#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

ROOT = File.expand_path('..', __dir__)
FIXTURE = File.join(ROOT, 'tests', 'fixtures', 'workflow-continuation-transcripts.yml')

COMMAND = /\A\s*`[^`]+`\s*\z/
CONCLUSION = /\A\*\*(?:结论|目标)：[^*]+\*\*\z/
REQUIRED_CARD_LABELS = ['已完成', '下一步'].freeze
PLAN_ONLY_COMMANDS = ['只保留方案', '转成实施任务', '继续聊聊', '取消'].freeze

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

def validate_pass_case(case_data)
  errors = []
  assistants = assistant_events(case_data)
  if assistants.empty?
    errors << '没有助手回复'
    return errors
  end

  assistants.each_with_index do |event, index|
    lines = normalized(event['text']).lines.map(&:chomp).reject { |line| line.strip.empty? }
    errors << "第 #{index + 1} 条助手回复首行不是单句结论" unless lines.first&.match?(CONCLUSION)
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
    handoff_index = event_index(case_data, 'assistant', '**下一步：**')
    errors << 'Workflow 交接没有出现在外部 Skill 结果之后' if first_external_index.nil? || handoff_index.nil? || handoff_index <= first_external_index
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
