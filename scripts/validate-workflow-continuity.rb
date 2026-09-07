#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

ROOT = File.expand_path('..', __dir__)
FIXTURE = File.join(ROOT, 'tests', 'fixtures', 'workflow-continuation-transcripts.yml')

COMMAND = /\A\s*`[^`]+`\s*\z/
CONCLUSION = /\A\*\*(?:结论|目标)：[^*]+\*\*\z/
REQUIRED_REPLY_LABELS = ['已完成', '下一步'].freeze
REQUIRED_CARD_LABELS = ['已完成', '下一步', '怎么回复'].freeze
PLAN_ONLY_COMMANDS = ['只保留方案', '转成实施任务', '继续聊聊', '取消'].freeze
ACTOR_WORDS = /(?:你|Codex|宿主|代码|测试)/
BOUNDARY_WORDS = /(?:不会|不修改|不写|不进入|不自动)/
HOST_ACTION = /(?:宿主动作|Implement|return-to-execution|手动进入 Plan|打开 Plan)/
NO_WRITE_MODES = %w[discussion check-only plan-only rca].freeze

def normalized(text)
  text.to_s.gsub("\r\n", "\n")
end

def assistant_events(case_data)
  case_data.fetch('events').select { |event| event['actor'] == 'assistant' }
end

def event_index(case_data, actor, fragment)
  case_data.fetch('events').index do |event|
    event['actor'] == actor && normalized(event['text']).include?(fragment)
  end
end

def command_blocks(text)
  lines = normalized(text).lines.map(&:chomp)
  blocks = []
  lines.each_with_index do |line, index|
    next unless line.match?(COMMAND)

    blocks << [line.strip, lines[index + 2]]
  end
  blocks
end

def validate_visible_reply(event, index)
  errors = []
  text = normalized(event['text'])
  lines = text.lines.map(&:chomp).reject { |line| line.strip.empty? }
  if lines.empty?
    return ["第 #{index + 1} 条助手回复为空"]
  end

  errors << "第 #{index + 1} 条助手回复首行不是单句结论" unless lines.first.match?(CONCLUSION)
  REQUIRED_REPLY_LABELS.each do |label|
    errors << "第 #{index + 1} 条助手回复缺少 **#{label}：**" unless text.include?("**#{label}：**")
  end

  next_section = text.split('**下一步：**', 2).last.to_s.split(/\n\*\*[^*]+：\*\*/, 2).first
  errors << "第 #{index + 1} 条助手回复没有写明下一步由谁执行" unless next_section.match?(ACTOR_WORDS)
  errors << "第 #{index + 1} 条助手回复没有写明当前不会做什么" unless text.match?(BOUNDARY_WORDS)

  blocks = command_blocks(text)
  errors << "第 #{index + 1} 条助手回复缺少可复制口令或宿主动作" if blocks.empty? && !text.match?(HOST_ACTION)
  blocks.each do |command, explanation|
    errors << "#{command} 后缺少 > 说明" unless explanation&.match?(/\A\s*>\s+\S/)
  end

  if NO_WRITE_MODES.include?(event['mode'].to_s) && (event['write'] == true || event['action'].to_s == 'FileChange')
    errors << "第 #{index + 1} 条助手回复在 #{event['mode']} 模式下产生了 FileChange"
  end

  errors
end

def validate_pass_case(case_data)
  errors = []
  assistants = assistant_events(case_data)
  if assistants.empty?
    errors << '没有助手回复'
    return errors
  end

  assistants.each_with_index do |event, index|
    errors.concat(validate_visible_reply(event, index))
  end

  if case_data['name'].include?('task-brief')
    route = assistants.find { |event| normalized(event['text']).include?('确认路由') }
    errors << 'Brief 确认后没有 Route 卡' unless route
    if route
      REQUIRED_CARD_LABELS.each do |label|
        errors << "Route 卡缺少 #{label}" unless normalized(route['text']).include?("**#{label}：**")
      end
    end
    confirm_index = event_index(case_data, 'user', '确认')
    route_index = event_index(case_data, 'assistant', '确认路由')
    errors << 'Route 卡没有出现在用户确认 Brief 之后' if confirm_index.nil? || route_index.nil? || route_index <= confirm_index
  end

  if case_data['name'].include?('plan-only')
    plan = assistants.find { |event| normalized(event['text']).include?('只保留方案') }
    errors << 'plan-only 结果没有收尾卡' unless plan
    if plan
      commands = command_blocks(plan['text']).map { |command, _| command.delete('`') }
      missing = PLAN_ONLY_COMMANDS - commands
      errors << "plan-only 收尾口令缺少：#{missing.join('、')}" unless missing.empty?
      command_blocks(plan['text']).each do |command, explanation|
        errors << "#{command} 后缺少 > 说明" unless explanation&.match?(/\A\s*>\s+\S/)
      end
    end
    route_confirm_index = event_index(case_data, 'user', '确认路由')
    plan_index = event_index(case_data, 'assistant', '只保留方案')
    errors << 'plan-only 收尾卡没有出现在确认 Route 之后' if route_confirm_index.nil? || plan_index.nil? || plan_index <= route_confirm_index
  end

  if case_data['name'].include?('external Skill')
    returned = assistants.last
    errors << '外部 Skill 返回后没有 Workflow 下一步' unless normalized(returned['text']).include?('**下一步：**')
    errors << '外部 Skill 返回后没有可复制口令' if command_blocks(returned['text']).empty?
    first_external_index = event_index(case_data, 'assistant', '外部 Skill')
    handoff_index = if first_external_index
                      case_data.fetch('events').each_with_index.find do |event, index|
                        index > first_external_index && event['actor'] == 'assistant' && normalized(event['text']).include?('**下一步：**')
                      end&.last
                    end
    errors << 'Workflow 交接没有出现在外部 Skill 结果之后' if first_external_index.nil? || handoff_index.nil? || handoff_index <= first_external_index
  end

  assertions = Array(case_data['assertions']).map(&:to_s)
  if assertions.include?('route_confirmation')
    route_index = case_data.fetch('events').each_with_index.find do |event, index|
      event['actor'] == 'assistant' && normalized(event['text']).include?('Route')
    end&.last
    route_text = route_index && case_data.fetch('events')[route_index]['text']
    errors << 'Route 卡缺少独立的确认路由口令' if route_text.nil? || !command_blocks(route_text).any? { |command, _| command.include?('确认路由') }
  end

  if assertions.include?('discussion_no_write')
    discussion_index = case_data.fetch('events').each_with_index.find do |event, index|
      index.positive? && event['actor'] == 'user' && normalized(event['text']).match?(/先聊一聊|继续聊聊/)
    end&.last
    if discussion_index
      changed = case_data.fetch('events')[(discussion_index + 1)..].to_a.any? do |event|
        event['write'] == true || event['action'].to_s == 'FileChange'
      end
      errors << '讨论模式下出现了 FileChange' if changed
    end
  end

  if assertions.include?('side_handoff')
    side_index = case_data.fetch('events').each_with_index.find do |event, index|
      event['actor'] == 'side' && event['side_handoff'] == true
    end&.last
    if side_index
      returned = case_data.fetch('events').each_with_index.find do |event, index|
        index > side_index && event['actor'] == 'assistant'
      end
      if returned.nil?
        errors << 'SIDE-HANDOFF 返回主会话后没有 Workflow 交接卡'
      else
        returned_text = normalized(returned.first['text'])
        REQUIRED_CARD_LABELS.each do |label|
          errors << "SIDE-HANDOFF 返回卡缺少 #{label}" unless returned_text.include?("**#{label}：**")
        end
        errors << 'SIDE-HANDOFF 返回卡缺少可复制口令' if command_blocks(returned_text).empty?
      end
    end
  end

  errors
end

def validate_fail_case(case_data)
  validate_pass_case(case_data).empty? ? ['旧 bad case 意外通过'] : []
end

data = YAML.safe_load(File.read(FIXTURE), permitted_classes: [], aliases: false)
errors = []
data.fetch('cases').each do |case_data|
  case_errors = if case_data.fetch('expected') == 'fail'
                  validate_fail_case(case_data)
                else
                  validate_pass_case(case_data)
                end
  case_errors.each { |message| errors << "#{case_data['name']}: #{message}" }
end

if errors.empty?
  puts "PASS workflow continuity: #{data.fetch('cases').length} transcript cases checked"
  exit 0
end

puts "FAIL workflow continuity: #{errors.length} issue(s)"
puts errors
exit 1
