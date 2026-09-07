#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

CONTINUITY_ROOT = File.expand_path('..', __dir__)
CONTINUITY_FIXTURE = File.join(CONTINUITY_ROOT, 'tests', 'fixtures', 'workflow-continuation-transcripts.yml')

COMMAND = /\A\s*`[^`]+`\s*\z/
CONCLUSION = /\A\*\*(?:结论|目标)：[^*]+\*\*\z/
REQUIRED_REPLY_LABELS = ['已完成', '下一步'].freeze
REQUIRED_CARD_LABELS = ['已完成', '下一步', '怎么回复'].freeze
BRIEF_LABELS = ['目标', '当前上下文/证据', '约束与授权', '范围/非目标', '验收标准/待确认项'].freeze
PLAN_ONLY_COMMANDS = ['确认计划，执行', '修改计划', '继续聊聊', '只保留方案', '取消'].freeze
ACTOR_WORDS = /(?:你|Codex|宿主|代码|测试)/
BOUNDARY_WORDS = /(?:不会|不修改|不写|不进入|不自动)/
HOST_ACTION = /(?:宿主动作|Implement|return-to-execution|手动进入 Plan|打开 Plan)/

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

    blocks << {
      command: line.strip,
      blank_line: lines[index + 1]&.strip&.empty?,
      explanation: lines[index + 2]
    }
  end
  blocks
end

def command_values(text)
  command_blocks(text).map { |block| block[:command].delete('`') }
end

def validate_command_explanations(errors, text, index)
  command_blocks(text).each do |block|
    command = block[:command]
    unless block[:blank_line]
      errors << "第 #{index + 1} 条助手回复的 #{command} 后缺少空行"
      next
    end

    explanation = block[:explanation]
    next if explanation&.match?(/\A\s*>\s+\S/)

    errors << "第 #{index + 1} 条助手回复的 #{command} 后缺少 > 说明"
  end
end

def validate_brief_reply(text, index)
  errors = []
  lines = text.lines.map(&:chomp).reject { |line| line.strip.empty? }
  errors << "第 #{index + 1} 条 Brief 首行不是目标" unless lines.first&.match?(CONCLUSION)

  labels = lines.each_with_object([]) do |line, found|
    match = line.strip.match(/\A\*\*(#{BRIEF_LABELS.map { |label| Regexp.escape(label) }.join('|')})：/)
    found << match[1] if match
  end
  errors << "第 #{index + 1} 条 Brief 没有保持五项固定顺序" unless labels == BRIEF_LABELS
  errors << "第 #{index + 1} 条 Brief 缺少确认提示" unless text.include?('请确认这份任务摘要')

  acceptance_start = text.index('**验收标准/待确认项：**')
  first_command_line = text.lines.find { |line| line.chomp.match?(COMMAND) }
  first_command = first_command_line && text.index(first_command_line)
  acceptance = if acceptance_start
                text[acceptance_start...(first_command || text.length)]
              else
                ''
              end
  unless acceptance.match?(ACTOR_WORDS) && acceptance.match?(/(?:下一步|接下来)/)
    errors << "第 #{index + 1} 条 Brief 没有在第五项说明下一步执行者"
  end

  required_commands = ['确认', '先聊一聊', '取消']
  errors << "第 #{index + 1} 条 Brief 缺少完整确认口令" unless required_commands.all? { |command| command_values(text).include?(command) }
  errors << "第 #{index + 1} 条 Brief 缺少修改口令" unless command_values(text).any? { |command| command.start_with?('修改：') }
  errors << "第 #{index + 1} 条 Brief 没有说明当前写入边界" unless text.match?(BOUNDARY_WORDS)
  validate_command_explanations(errors, text, index)
  errors
end

def validate_full_reply(text, index)
  errors = []
  lines = text.lines.map(&:chomp).reject { |line| line.strip.empty? }
  errors << "第 #{index + 1} 条助手回复首行不是单句结论" unless lines.first&.match?(CONCLUSION)
  REQUIRED_REPLY_LABELS.each do |label|
    errors << "第 #{index + 1} 条助手回复缺少 **#{label}：**" unless text.include?("**#{label}：**")
  end

  next_section = text.split('**下一步：**', 2).last.to_s.split(/\n\*\*[^*]+：\*\*/, 2).first
  errors << "第 #{index + 1} 条助手回复没有写明下一步由谁执行" unless next_section.match?(ACTOR_WORDS)
  errors << "第 #{index + 1} 条助手回复没有写明当前不会做什么" unless text.match?(BOUNDARY_WORDS)

  blocks = command_blocks(text)
  errors << "第 #{index + 1} 条助手回复缺少可复制口令或宿主动作" if blocks.empty? && !text.match?(HOST_ACTION)
  validate_command_explanations(errors, text, index)
  errors
end

def validate_visible_reply(event, index)
  text = normalized(event['text'])
  return ["第 #{index + 1} 条助手回复为空"] if text.lines.all? { |line| line.strip.empty? }

  first_line = text.lines.map(&:chomp).find { |line| !line.strip.empty? }
  first_line&.start_with?('**目标：') ? validate_brief_reply(text, index) : validate_full_reply(text, index)
end

def event_has_write?(event)
  event['write'] == true || event['action'].to_s == 'FileChange'
end

def infer_mode(text)
  plan_only = text.match?(/(?:只(?:制定|做|写|出)|只规划|(?:请|帮我|需要|希望)\s*(?:制定|规划|做|写|出|给我|提供)?)[^\n]{0,20}(?:方案|计划|Plan)/i)
  plan_only ||= text.match?(/\A(?:请|帮我|需要)\S{0,8}(?:计划|Plan)\z/i)
  return 'plan-only' if plan_only && !text.match?(/修复|实施|改动|执行|实现/)
  return 'check-only' if text.include?('$rca-analyze') && !text.match?(/修复|实施|改动/)
  return 'check-only' if text.match?(/只检查|只读|只分析|不要(?:修改|改)|不修改文件/) && !text.match?(/修复|实施|改动/)

  'implementation'
end

def explicit_plan_requested?(text)
  return false if text.match?(/(?:不要|无需|不需要|不用)[^\n]{0,12}(?:计划|Plan)/i)

  text.match?(/(?:制定|规划|要求|想要|需要|希望|给我|提供|先(?:给我|做|制定|写|出)?|进入|使用|调用)[^\n]{0,20}(?:计划|Plan)/i)
end

def infer_size(text)
  return 'large' if text.match?(/\bLarge\b|大型|迁移|架构|跨模块|多子系统/)
  return 'medium' if text.match?(/\bMedium\b|中型|性能|并发|多文件/)

  'small'
end

def infer_stage(text)
  return 'brief' if text.include?('$task-brief')
  return 'route' if text.include?('$task-router')
  return 'rca' if text.include?('$rca-analyze')
  return 'option' if text.include?('$option-explorer')
  return 'retrospective' if text.include?('$repo-retrospective')

  'discussion'
end

def initial_user_text(case_data)
  case_data.fetch('events').find { |event| event['actor'] == 'user' }&.fetch('text', '').to_s
end

def workflow_state(case_data)
  metadata = case_data.fetch('workflow', {})
  first_text = initial_user_text(case_data)
  mode = (metadata['mode'] || infer_mode(first_text)).to_s
  size = (metadata['size'] || infer_size(first_text)).to_s
  brief_required = if metadata.key?('brief_required')
                     metadata['brief_required'] == true
                   else
                     first_text.include?('$task-brief') || metadata['stage'].to_s == 'brief'
                   end
  plan_required = if metadata.key?('plan_required')
                    metadata['plan_required'] == true
                  else
                    mode == 'plan-only' || (mode == 'implementation' && (%w[medium large].include?(size) || explicit_plan_requested?(first_text)))
                  end
  {
    mode: mode,
    size: size,
    bug: metadata.key?('bug') ? metadata['bug'] == true : first_text.match?(/Bug|故障|失败|无法|误删|卡顿/),
    stage: (metadata['stage'] || infer_stage(first_text)).to_s,
    brief_required: brief_required,
    brief_confirmed: metadata['brief_confirmed'] == true || !brief_required,
    plan_required: plan_required,
    route_confirmed: metadata['route_confirmed'] == true,
    plan_visible: metadata['plan_visible'] == true,
    execution_authorized: metadata['execution_authorized'] == true,
    rca_confirmed: metadata['rca_confirmed'] == true,
    paused: false,
    cancelled: false,
    terminal: false,
    option_active: false,
    option_selected: false,
    scope_changed: false,
    execution_requested_without_plan: false
  }
end

def next_stage_after_route(state)
  return 'investigation' if state[:mode] == 'check-only'
  return 'rca' if state[:bug]
  return 'plan' if state[:plan_required]

  'implementation'
end

def next_stage_after_rca(state)
  state[:plan_required] ? 'plan' : 'implementation'
end

def can_resume_execution?(state)
  return true if state[:execution_authorized]
  return false unless state[:mode] == 'implementation' && state[:route_confirmed] && state[:size] == 'small' && !state[:plan_required]

  !state[:bug] || state[:rca_confirmed]
end

def apply_user_event(state, text, scope_changed: false)
  normalized_text = normalized(text).strip
  state[:plan_required] = true if explicit_plan_requested?(normalized_text)

  if scope_changed || normalized_text.match?(/范围(?:发生|已经|有)?(?:实质)?(?:改变|变化|变了)|(?:改|修改)了?范围|扩大范围|缩小范围/)
    state[:scope_changed] = true
    state[:route_confirmed] = false
    state[:plan_visible] = false
    state[:execution_authorized] = false
    state[:option_active] = false
    state[:option_selected] = false
    state[:stage] = 'route'
  end

  if normalized_text.match?(/\A(?:取消|取消当前任务)[。！!]?\z/)
    state[:cancelled] = true
    state[:terminal] = true
    state[:paused] = false
    return
  end

  if normalized_text.match?(/先聊一聊|继续聊聊/)
    state[:paused] = true
    return
  end

  if normalized_text.match?(/\A(?:整理 brief|整理任务摘要)[。！!]?\z/)
    was_check_only = state[:mode] == 'check-only'
    state[:paused] = false
    state[:stage] = 'brief'
    state[:brief_required] = true
    state[:brief_confirmed] = false
    state[:route_confirmed] = false
    state[:plan_visible] = false
    state[:execution_authorized] = false
    state[:scope_changed] = false
    if was_check_only
      state[:mode] = 'implementation'
      state[:plan_required] = %w[medium large].include?(state[:size])
    end
    return
  end

  if normalized_text.match?(/\A确认路由[。！!]?\z/)
    return if state[:brief_required] && !state[:brief_confirmed]

    state[:paused] = false
    state[:route_confirmed] = true
    state[:scope_changed] = false
    state[:stage] = next_stage_after_route(state)
    return
  end

  if normalized_text.match?(/\A确认计划，执行[。！!]?\z|\A执行[。！!]?\z/)
    if state[:plan_visible]
      state[:paused] = false
      state[:execution_authorized] = true
      state[:scope_changed] = false
      state[:stage] = 'implementation'
    else
      state[:execution_requested_without_plan] = true
    end
    return
  end

  if normalized_text.match?(/\A(?:继续执行|恢复执行|按原计划执行)[。！!]?\z/)
    state[:paused] = false if can_resume_execution?(state) && !state[:scope_changed]
    return
  end

  if normalized_text.match?(/\A确认[。！!]?\z/) && state[:stage] == 'brief'
    state[:paused] = false
    state[:brief_confirmed] = true
    state[:stage] = 'route'
    return
  end

  if normalized_text.match?(/\A进入 option[。！!]?\z/)
    state[:paused] = false
    state[:option_active] = true
    state[:stage] = 'option'
    return
  end

  if normalized_text.match?(/\A跳过 option[。！!]?\z/)
    state[:paused] = false
    state[:option_active] = false
    state[:stage] = next_stage_after_route(state)
    return
  end

  if normalized_text.match?(/\A(?:采用|选择)(?: [A-Z]|其他方向)(?:：[^。！？!?]*)?[。！？!?]?\z/)
    state[:paused] = false
    state[:option_active] = false
    state[:option_selected] = true
    state[:stage] = state[:route_confirmed] ? next_stage_after_route(state) : 'route'
    return
  end

  if normalized_text.match?(/\A回到 Plan[。！!]?\z/)
    state[:paused] = false
    state[:option_active] = false
    state[:plan_required] = true
    state[:plan_visible] = false
    state[:execution_authorized] = false
    state[:stage] = 'plan'
    return
  end

  if normalized_text.match?(/\A只保留比较结果[。！!]?\z|\A只保留方案[。！!]?\z/)
    state[:paused] = false
    state[:terminal] = true
    return
  end

  if normalized_text.match?(/\A修改计划[。！!]?\z/)
    state[:paused] = false
    state[:stage] = 'plan'
    state[:plan_visible] = false
    state[:execution_authorized] = false
  end
end

def write_errors(state)
  return ['write_after_cancel: 取消后仍然产生了 FileChange'] if state[:cancelled]
  return ['write_after_terminal: 终止选择后仍然产生了 FileChange'] if state[:terminal]
  return ['write_during_discussion: 讨论模式下产生了 FileChange'] if state[:paused]
  return ['write_before_brief_confirmation: Brief 尚未确认就产生了 FileChange'] if state[:brief_required] && !state[:brief_confirmed]
  return ['write_before_route_confirmation: Route 尚未确认就产生了 FileChange'] unless state[:route_confirmed]
  return ['write_in_check_only: check-only 模式下产生了 FileChange'] if state[:mode] == 'check-only'
  return ['write_before_option_selection: Option 尚未完成采用选择就产生了 FileChange'] if state[:option_active] && !state[:option_selected]
  return ['execution_before_native_plan: native Plan 尚未出现就收到执行授权并产生了 FileChange'] if state[:execution_requested_without_plan]
  return ['write_without_execution_authorization: 规划结果尚未获得执行授权就产生了 FileChange'] if state[:plan_required] && !state[:execution_authorized]
  return ['write_without_native_plan: Medium/Large 或用户要求规划的任务尚未出现原生 Plan'] if state[:plan_required] && !state[:plan_visible]
  return ['bug_write_before_rca: Bug 根因尚未确认就产生了 FileChange'] if state[:bug] && !state[:rca_confirmed]
  return ['write_without_implementation_request: 当前没有实施授权就产生了 FileChange'] unless state[:mode] == 'implementation' || state[:execution_authorized]

  []
end

def validate_conversation(case_data)
  errors = []
  state = workflow_state(case_data)

  case_data.fetch('events').each_with_index do |event, index|
    case event['actor']
    when 'user'
      apply_user_event(state, event['text'], scope_changed: event['scope_changed'] == true)
    when 'assistant'
      if event['native_plan'] == true
        state[:plan_visible] = true
        state[:execution_requested_without_plan] = false
      end
      if event['host_action'].to_s.match?(/\A(?:Implement|return-to-execution)\z/) || event['execution_mode'] == true
        if state[:plan_visible]
          state[:execution_authorized] = true
          state[:paused] = false
          state[:stage] = 'implementation'
        else
          state[:execution_requested_without_plan] = true
        end
      end
      if event['root_cause_confirmed'] == true
        state[:rca_confirmed] = true
        state[:stage] = next_stage_after_rca(state)
      end
      next unless event_has_write?(event)

      write_errors(state).each do |error|
        errors << "#{error} (第 #{index + 1} 个事件)"
      end
    end
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
  errors.concat(validate_conversation(case_data))

  if case_data['name'].include?('task-brief')
    route = assistants.find { |event| normalized(event['text']).include?('确认路由') }
    errors << 'brief_route_missing: Brief 确认后没有 Route 卡' unless route
    if route
      REQUIRED_CARD_LABELS.each do |label|
        errors << "Route 卡缺少 #{label}" unless normalized(route['text']).include?("**#{label}：**")
      end
    end
    confirm_index = event_index(case_data, 'user', '确认')
    route_index = event_index(case_data, 'assistant', '确认路由')
    errors << 'brief_route_order_invalid: Route 卡没有出现在用户确认 Brief 之后' if confirm_index.nil? || route_index.nil? || route_index <= confirm_index
  end

  if case_data['name'].include?('plan-only')
    plan = assistants.find { |event| normalized(event['text']).include?('确认计划，执行') }
    errors << 'plan_only_missing_execution_handoff: plan-only 结果没有执行交接卡' unless plan
    if plan
      errors << 'plan_only_missing_native_plan: plan-only 结果没有标记真实 native Plan' unless plan['native_plan'] == true
      commands = command_values(plan['text'])
      missing = PLAN_ONLY_COMMANDS - commands
      errors << "plan-only 收尾口令缺少：#{missing.join('、')}" unless missing.empty?
      validate_command_explanations(errors, plan['text'], assistants.index(plan))
    end
    route_confirm_index = event_index(case_data, 'user', '确认路由')
    plan_index = event_index(case_data, 'assistant', '确认计划，执行')
    errors << 'plan_only_order_invalid: plan-only 收尾卡没有出现在确认 Route 之后' if route_confirm_index.nil? || plan_index.nil? || plan_index <= route_confirm_index
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
    errors << 'route_confirmation_missing: Route 卡缺少独立的确认路由口令' if route_text.nil? || !command_blocks(route_text).any? { |block| block[:command].include?('确认路由') }
  end

  if assertions.include?('discussion_no_write') && validate_conversation(case_data).any? { |error| error.start_with?('write_during_discussion:') }
    errors << '讨论模式下出现了 FileChange'
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
        errors << 'side_handoff_missing_card: SIDE-HANDOFF 返回主会话后没有 Workflow 交接卡'
      else
        returned_text = normalized(returned.first['text'])
        missing_card_labels = REQUIRED_CARD_LABELS.reject { |label| returned_text.include?("**#{label}：**") }
        unless missing_card_labels.empty?
          errors << "side_handoff_missing_card: SIDE-HANDOFF 返回卡缺少 #{missing_card_labels.join('、')}"
        end
        errors << 'side_handoff_missing_command: SIDE-HANDOFF 返回卡缺少可复制口令' if command_blocks(returned_text).empty?
      end
    end
  end

  errors
end

def validate_fail_case(case_data)
  errors = validate_pass_case(case_data)
  return ['旧 bad case 意外通过'] if errors.empty?

  expected_errors = Array(case_data['expected_errors']).map(&:to_s)
  return ['负面案例没有声明 expected_errors'] if expected_errors.empty?

  missing = expected_errors.reject do |code|
    errors.any? { |error| error.start_with?("#{code}:") }
  end
  missing.empty? ? [] : ["没有命中预期失败原因：#{missing.join('、')}；实际错误：#{errors.join(' | ')}"]
end

def run_continuity_validation(data = YAML.safe_load(File.read(CONTINUITY_FIXTURE), permitted_classes: [], aliases: false))
  errors = []
  data.fetch('cases').each do |case_data|
    case_errors = if case_data.fetch('expected') == 'fail'
                    validate_fail_case(case_data)
                  else
                    validate_pass_case(case_data)
                  end
    case_errors.each { |message| errors << "#{case_data['name']}: #{message}" }
  end
  errors
end

if __FILE__ == $PROGRAM_NAME
  errors = run_continuity_validation
  if errors.empty?
    data = YAML.safe_load(File.read(CONTINUITY_FIXTURE), permitted_classes: [], aliases: false)
    puts "PASS workflow continuity: #{data.fetch('cases').length} transcript cases checked"
    exit 0
  end

  puts "FAIL workflow continuity: #{errors.length} issue(s)"
  puts errors
  exit 1
end
