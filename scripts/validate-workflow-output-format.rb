#!/usr/bin/env ruby
# frozen_string_literal: true

ROOT = File.expand_path('..', __dir__)

TARGETS = %w[
  engineering-workflow
  task-brief
  task-router
  rca-analyze
  option-explorer
  repo-retrospective
].freeze

DISPLAY_LABELS = [
  '结论',
  '目标',
  '当前上下文/证据',
  '约束与授权',
  '范围/非目标',
  '验收标准/待确认项',
  '已完成',
  '下一步',
  '需要你确认',
  '怎么回复',
  '请确认',
  '请回复',
  '当前判断',
  '原因',
  '边界',
  '切换',
  '路由',
  '模式',
  '类型',
  '限制',
  'Plan 请求',
  '任务目标',
  '已确认的 RCA/证据',
  '范围',
  '非目标',
  '约束',
  '验收与验证',
  '选项检查',
  '探索完成',
  '复盘结果',
  '建议去向',
  'RCA 级别',
  '现象与期望',
  '复现/反馈回路',
  '证据与调用链',
  '根因',
  '影响范围',
  '修复边界',
  '回归验证',
  '未决问题',
  '代表性问题',
  '共性不变量',
  '触类旁通清单'
].freeze

META_LABELS = %w[路由 模式 类型 限制].freeze
TASK_BRIEF_LABELS = %w[
  目标
  当前上下文/证据
  约束与授权
  范围/非目标
  验收标准/待确认项
].freeze

PLAN_REQUEST_LABELS = [
  '任务目标',
  '已确认的 RCA/证据',
  '范围',
  '非目标',
  '约束',
  '验收与验证'
].freeze

SEMANTIC_REQUIREMENTS = {
  'engineering-workflow' => {
    'native Plan 不可调用时必须立即交接请求' => [
      'immediately output a filled `Plan 请求`',
      'do not require a separate text acknowledgement after planning',
      'Implement/return-to-execution action',
      '确认计划，执行'
    ]
  },
  'task-brief' => {
    '任务摘要四选项必须使用完整用户文案' => [
      '请确认这份任务摘要。',
      '`修改：请把……改成……`',
      '你同意这份任务摘要。Codex 接下来会',
      '你不同意当前的任务摘要。Codex 会',
      '你暂时不确认这份任务摘要',
      '你要停止当前任务。Codex 不会'
    ]
  },
  'task-router' => {
    'user-run Plan 必须先给输入并直接消费可见结果' => [
      'always show a handoff with a filled, copyable `Plan 请求` immediately',
      'requiring proof of a manual entry before providing that input creates a deadlock',
      'Do not require an extra textual completion acknowledgement',
      'Implement action or the host has otherwise returned the task to execution mode'
    ]
  }
}.freeze

STAGE_CONTINUITY_REQUIREMENTS = {
  'engineering-workflow' => [
    'Public Skill stage entry and continuation',
    'A direct public Skill invocation',
    'stage continuation handoff',
    'next available handoff or an explicit terminal choice'
  ],
  'task-brief' => [
    'first stage of the full Workflow',
    'continues to `$task-router`',
    'standalone Brief'
  ],
  'task-router' => [
    'Stage completion contract',
    'direct public `$task-router` entry',
    'next-stage handoff',
    'show the result handoff with `整理 brief`'
  ],
  'rca-analyze' => [
    'public Skill is invoked directly',
    'explicit handoff back into the full repair Workflow'
  ],
  'option-explorer' => [
    'immediately show the required next-stage handoff',
    'direct Option entry remains connected to the full Workflow'
  ],
  'repo-retrospective' => [
    'optional terminal stage',
    'terminal or write handoff'
  ]
}.freeze

CONTINUATION_COMMAND_REQUIREMENTS = {
  'engineering-workflow' => '`继续聊聊`',
  'task-router' => '`继续聊聊`',
  'rca-analyze' => '`继续聊聊`',
  'option-explorer' => '`继续聊聊`',
  'repo-retrospective' => '`继续聊聊`',
  'task-brief' => '`先聊一聊`'
}.freeze

PLAN_ONLY_HANDOFF_REQUIREMENTS = [
  '`只保留方案`',
  '`转成实施任务`',
  '`继续聊聊`',
  '`取消`',
  '转成实施任务` starts a new Brief/Route authorization cycle',
  'For `plan-only`, show the planning-end card'
].freeze

EXTERNAL_SKILL_HANDOFF_REQUIREMENTS = [
  'temporarily calls an external Skill',
  'external Skill must not be edited',
  'start with the conclusion',
  'subject-action-result Chinese',
  'return the result to'
].freeze

EXTERNAL_WRAPPER_REQUIREMENTS = {
  '.agents/skills/engineering-workflow/SKILL.md' => [
    '本次调用外部 Skill 时，先附加下面这段临时说明',
    '不要替 Workflow 结束任务'
  ],
  'docs/codex-workflow-context.md' => [
    '本次调用外部 Skill 时使用这段临时说明',
    '不要替 Workflow 结束任务'
  ]
}.freeze

STALE_CONTINUITY_RULES = {
  '.agents/skills/engineering-workflow/SKILL.md' => [
    'After a local Skill returns, re-evaluate the intent; do not automatically chain another Skill or jump to `$task-brief`',
    'report the native result and stop without an execution confirmation'
  ],
  '.agents/skills/task-router/SKILL.md' => [
    'reports findings and stops',
    'independent lower-level entry and does not require the Workflow’s Brief gate',
    'Never auto-chain multiple local Skills',
    'For a `plan-only` result, report the Plan and state that the task ends at planning; do not ask for an execution confirmation'
  ],
  '.agents/skills/rca-analyze/SKILL.md' => [
    'Do not silently chain `$task-brief`, `$task-router`'
  ],
  '.agents/skills/task-router/references/routing-cases.md' => [
    'Never auto-chain multiple local Skills',
    'remains an independent lower-level route and does not inherit the Workflow’s Brief confirmation gate'
  ],
  'docs/codex-workflow-context.md' => [
    'Workflow never auto-chains multiple local Skills',
    'A local helper or RCA call never grants routing, Plan, execution, or writes by itself'
  ]
}.freeze

ROUTING_CASE_REQUIREMENTS = [
  '宿主没有 callable native Plan，也没有预先声明手动 Plan 入口',
  'Output the filled Plan request immediately',
  'Consume the visible native result directly',
  'explicit host Implement/return-to-execution action',
  '## Public Skill stage-continuation acceptance transcripts',
  '### Scenario 4 — Direct RCA entry returns to Brief',
  '### Scenario 5 — Direct Router entry continues after Route',
  '### Scenario 6 — Direct Option entry returns to Plan',
  '### Scenario 7 — Direct Brief entry returns to Route',
  '### Scenario 8 — Check-only result has a visible next choice'
].freeze

HUMAN_LANGUAGE_ACCEPTANCE_REQUIREMENTS = [
  '## 中文可读性回归验收（10 套具体场景）',
  '### 场景 1：RCA 解释文本替换机制',
  '### 场景 2：Route 说明下一步',
  '### 场景 3：Brief 解释技术约束',
  '### 场景 4：RCA 的 `整理 brief` 口令',
  '### 场景 5：check-only 调查结束',
  '### 场景 6：Option 比较两条路线',
  '### 场景 7：手动 native Plan 提示',
  '### 场景 8：直接调用 `$rca-analyze`',
  '### 场景 9：复盘结果',
  '### 场景 10：完成报告',
  '只改表达，不改事实、权限、数值或结论',
  '复制时只得到 `整理 brief`'
].freeze

PLAN_BEHAVIOR_SKILL_TARGETS = [
  '.agents/skills/engineering-workflow/SKILL.md',
  '.agents/skills/task-router/SKILL.md',
  '.agents/skills/option-explorer/SKILL.md',
].freeze

PLAN_BEHAVIOR_DOC_TARGETS = [
  '.agents/skills/task-router/references/routing-cases.md',
  'docs/codex-workflow-context.md'
].freeze

PLAN_COMMAND_PATTERN = /\A\s*`([^`]+)`\s*\z/.freeze

# The words “Plan 已完成” are valid in a result heading. Only the old
# instruction that asked the user to send a duplicate acknowledgement is stale.
OBSOLETE_PLAN_COMPLETION_REPLY = '再回复 `Plan 已完成`'.freeze

MANUAL_PLAN_SCENARIO_ONE_REQUIREMENTS = [
  '### Scenario 1 — Medium implementation without a callable Plan entry',
  '**Step 1 — Workflow reply:**',
  '**Plan 请求：**',
  '**Step 2 — User action:**',
  '**Step 3 — Native Plan reply:**',
  'No extra textual completion acknowledgement is requested.'
].freeze

OBSOLETE_PLAN_ENTRY_CONFIRMATION = ['确认进入', 'Plan'].join(' ').freeze
OBSOLETE_OPTION_CONTINUE_REPLY = ['确认', '继续'].join.freeze

MANUAL_PLAN_SCENARIO_TWO_REQUIREMENTS = [
  '### Scenario 2 — Large implementation after Option selection',
  '**Step 1 — Option reply:**',
  '**Step 2 — User selection:**',
  '**Step 3 — Workflow reply:**',
  'The selected direction flows directly into callable Plan or the filled manual Plan request.'
].freeze

OBSOLETE_UNCONDITIONAL_EXECUTION_GATES = [
  'After native Plan, implementation waits for the user’s execution confirmation.',
  'After native Plan, implementation waits for `确认计划，执行`',
  'complete native Plan, then ask `确认计划，执行`'
].freeze

MANUAL_PLAN_SCENARIO_THREE_REQUIREMENTS = [
  '### Scenario 3 — Host returns from native Plan to execution',
  '**Step 1 — Native Plan reply:**',
  '**Step 2 — User host action:**',
  '**Step 3 — Workflow execution reply:**',
  'No completion receipt or duplicate execution confirmation is requested.'
].freeze

def relative_path(path)
  path.sub("#{ROOT}/", '')
end

def fenced_blocks(path)
  blocks = []
  current = nil

  File.readlines(path).each_with_index do |raw_line, index|
    line = raw_line.chomp

    if current
      if line.match?(/\A```\s*\z/)
        current[:end_line] = index + 1
        blocks << current
        current = nil
      else
        current[:lines] << [index + 1, line]
      end
    elsif line =~ /\A```([A-Za-z0-9_-]*)\s*\z/
      current = {
        language: Regexp.last_match(1),
        start_line: index + 1,
        lines: []
      }
    end
  end

  blocks << { unclosed: true, start_line: current[:start_line] } if current
  blocks
end

def add_error(errors, path, line, message)
  errors << "#{relative_path(path)}:#{line}: #{message}"
end

def response_block?(line)
  line.match?(/\*\*(?:怎么回复|请确认|请回复|切换)\*\*/)
end

def command_line?(line)
  !line.nil? && line.match?(PLAN_COMMAND_PATTERN)
end

def validate_reply_commands(errors, path, lines)
  if lines.all? { |_, line| !response_block?(line) }
    return
  end

  lines.each do |line_number, line|
    stripped = line.lstrip
    next if stripped.empty?

    if stripped.start_with?('- ')
      add_error(errors, path, line_number, '回复命令不能用 `-` 列表符开头')
    elsif stripped.start_with?('* ')
      add_error(errors, path, line_number, '回复命令不能用 `*` 列表符开头')
    elsif stripped.match?(/\A\d+\.\s*/)
      add_error(errors, path, line_number, '回复命令不能用数字序号开头')
    end
  end

  command_lines = lines.each_with_index.select do |(_, line), _|
    command_line?(line)
  end

  if command_lines.empty?
    add_error(errors, path, lines.first[0], '回复/切换卡片必须包含独占一段的口令行')
    return
  end

  indices = lines.map(&:first)

  command_lines.each do |line_number, line|
    next_index = indices.index(line_number)
    if next_index.nil?
      next
    end

    spacer_entry = lines[next_index + 1]
    if spacer_entry.nil?
      add_error(errors, path, line_number, '每个口令后应有空行和独立说明段')
      next
    end

    _, spacer_line = spacer_entry
    unless spacer_line.strip.empty?
      add_error(errors, path, line_number, '口令和说明必须分成两个段落，中间空一行')
      next
    end

    explanation_entry = lines[next_index + 2]
    if explanation_entry.nil? || explanation_entry[1].strip.empty?
      add_error(errors, path, line_number, '口令后的空行下面必须有独立说明段')
      next
    end

    if command_line?(explanation_entry[1])
      add_error(errors, path, line_number, '口令后必须是说明，不能直接跟另一个口令')
    elsif !explanation_entry[1].match?(/\A\s*>\s+\S/)
      add_error(errors, path, explanation_entry[0], '口令的说明必须以 `> ` 开头，以便与口令明显分开')
    end
  end
end

def validate_plan_request_order(errors, path, blocks)
  block = blocks.find do |candidate|
    candidate[:lines].any? { |_, line| line.include?('**Plan 请求：**') }
  end

  unless block
    add_error(errors, path, 1, '没有找到 Plan 请求输出模板')
    return
  end

  labels = block[:lines].each_with_object([]) do |(_, line), found|
    match = line.strip.match(/\A\*\*(#{PLAN_REQUEST_LABELS.map { |label| Regexp.escape(label) }.join('|')})：\*\*\z/)
    found << match[1] if match
  end

  return if labels == PLAN_REQUEST_LABELS

  add_error(errors, path, block[:start_line], "Plan 请求必须保持六项且顺序固定：#{PLAN_REQUEST_LABELS.join('、')}")
end

def validate_block(errors, path, block)
  if block[:unclosed]
    add_error(errors, path, block[:start_line], '未闭合的 Markdown 代码块')
    return
  end

  if block[:language] != 'markdown'
    add_error(errors, path, block[:start_line], "输出示例应使用 markdown 代码块，当前为 #{block[:language].inspect}")
  end

  lines = block[:lines]
  visible = lines.reject { |_, line| line.strip.empty? }
  return if visible.empty?

  first_line_number, first_line = visible.first
  summary_match = first_line.strip.match(/\A\*\*(?:结论|目标)：(.+)\*\*\z/)
  if summary_match.nil?
    add_error(errors, path, first_line_number, '首行必须是单句加粗的结论或目标')
  elsif summary_match[1].scan(/[。！？!?]/).length > 1
    add_error(errors, path, first_line_number, '首行核心结论必须保持为单句')
  end

  label_pattern = DISPLAY_LABELS.map { |label| Regexp.escape(label) }.join('|')
  field_pattern = /\A\*\*(#{label_pattern})：\*\*(.*)\z/
  raw_field_pattern = /\A(#{label_pattern})：(.*)\z/

  lines.each do |line_number, line|
    text = line.strip
    next if text.empty?

    if (match = text.match(field_pattern))
      label = match[1]
      trailing = match[2].strip
      summary_line = line_number == first_line_number && %w[结论 目标].include?(label)
      next if summary_line

      if META_LABELS.include?(label)
        add_error(errors, path, line_number, "#{label} 的值应独立分行，不能继续串联其他字段") if trailing.include?('；')
      elsif !trailing.empty?
        add_error(errors, path, line_number, "#{label} 标签后应换行，详情不能挤在同一行")
      end
    elsif text.match?(raw_field_pattern)
      add_error(errors, path, line_number, '字段标签必须使用 Markdown 加粗并独占一行')
    end
  end

  route_lines = lines.select { |_, line| line.include?('路由：') }
  route_lines.each do |line_number, line|
    metadata_count = META_LABELS.count { |label| line.include?("#{label}：") }
    if metadata_count > 1 || line.count('；') >= 1
      add_error(errors, path, line_number, '路由、模式、类型和限制必须分行')
    end
  end

  validate_reply_commands(errors, path, lines) if lines.any? { |_, line| line.match?(/怎么回复|请确认|请回复|切换/) }
end

errors = []

TARGETS.each do |skill|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  unless File.file?(path)
    add_error(errors, path, 1, '目标 Skill 文件不存在')
    next
  end

  blocks = fenced_blocks(path)
  if blocks.empty?
    add_error(errors, path, 1, '没有找到可验证的输出模板')
    next
  end

  blocks.each { |block| validate_block(errors, path, block) }

  validate_plan_request_order(errors, path, blocks) if skill == 'task-router'

  next unless skill == 'task-brief'

  first_block = blocks.find { |block| !block[:unclosed] }
  next unless first_block

  labels = first_block[:lines].map do |_, line|
    match = line.strip.match(/\A\*\*(#{TASK_BRIEF_LABELS.map { |label| Regexp.escape(label) }.join('|')})：/)
    match && match[1]
  end.compact
  unless labels == TASK_BRIEF_LABELS
    add_error(errors, path, first_block[:start_line], "Task Brief 必须保持五项且顺序固定：#{TASK_BRIEF_LABELS.join('、')}")
  end
end

EXTERNAL_WRAPPER_REQUIREMENTS.each do |relative, tokens|
  path = File.join(ROOT, relative)
  content = File.read(path)
  missing = tokens.reject { |token| content.include?(token) }
  next if missing.empty?

  add_error(errors, path, 1, "外部 Skill 临时说明缺少：#{missing.join('、')}")
end

SEMANTIC_REQUIREMENTS.each do |skill, requirements|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  content = File.read(path)

  requirements.each do |label, tokens|
    missing = tokens.reject { |token| content.include?(token) }
    next if missing.empty?

    add_error(errors, path, 1, "#{label} 缺少语义契约：#{missing.join('、')}")
  end
end

STAGE_CONTINUITY_REQUIREMENTS.each do |skill, tokens|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  content = File.read(path)
  missing = tokens.reject { |token| content.include?(token) }
  next if missing.empty?

  add_error(errors, path, 1, "阶段连续性契约缺少：#{missing.join('、')}")
end

CONTINUATION_COMMAND_REQUIREMENTS.each do |skill, command|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  content = File.read(path)
  next if content.include?(command)

  add_error(errors, path, 1, "阶段等待卡缺少固定口令：#{command}")
end

task_router_path = File.join(ROOT, '.agents', 'skills', 'task-router', 'SKILL.md')
task_router_content = File.read(task_router_path)
missing_plan_only = PLAN_ONLY_HANDOFF_REQUIREMENTS.reject { |token| task_router_content.include?(token) }
unless missing_plan_only.empty?
  add_error(errors, task_router_path, 1, "plan-only 收尾契约缺少：#{missing_plan_only.join('、')}")
end

TARGETS.each do |skill|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  content = File.read(path)
  missing_external = EXTERNAL_SKILL_HANDOFF_REQUIREMENTS.reject { |token| content.include?(token) }
  next if missing_external.empty?

  add_error(errors, path, 1, "外部 Skill 临时调用契约缺少：#{missing_external.join('、')}")
end

STALE_CONTINUITY_RULES.each do |relative, tokens|
  path = File.join(ROOT, relative)
  content = File.read(path)
  stale = tokens.select { |token| content.include?(token) }
  next if stale.empty?

  add_error(errors, path, 1, "仍包含过时的阶段断链规则：#{stale.join('、')}")
end

routing_cases_path = File.join(ROOT, '.agents', 'skills', 'task-router', 'references', 'routing-cases.md')
routing_cases = File.read(routing_cases_path)
missing_routing_cases = ROUTING_CASE_REQUIREMENTS.reject { |token| routing_cases.include?(token) }
unless missing_routing_cases.empty?
  add_error(errors, routing_cases_path, 1, "手动 Plan 验收案例缺少：#{missing_routing_cases.join('、')}")
end

missing_human_language_cases = HUMAN_LANGUAGE_ACCEPTANCE_REQUIREMENTS.reject do |token|
  routing_cases.include?(token)
end
unless missing_human_language_cases.empty?
  add_error(errors, routing_cases_path, 1, "中文可读性验收案例缺少：#{missing_human_language_cases.join('、')}")
end

PLAN_BEHAVIOR_SKILL_TARGETS.each do |relative|
  path = File.join(ROOT, relative)
  next unless File.read(path).include?(OBSOLETE_PLAN_COMPLETION_REPLY)

  add_error(errors, path, 1, '仍包含无效的 Plan 文字完成回执')
end


missing_scenario_one = MANUAL_PLAN_SCENARIO_ONE_REQUIREMENTS.reject do |token|
  routing_cases.include?(token)
end
unless missing_scenario_one.empty?
  add_error(errors, routing_cases_path, 1, "真实验收场景 1 缺少：#{missing_scenario_one.join('、')}")
end

plan_entry_targets = PLAN_BEHAVIOR_SKILL_TARGETS
plan_entry_targets.each do |relative|
  path = File.join(ROOT, relative)
  next unless File.read(path).include?(OBSOLETE_PLAN_ENTRY_CONFIRMATION)

  add_error(errors, path, 1, '仍包含选择 Option 后的冗余 Plan 入口确认')
end


PLAN_BEHAVIOR_SKILL_TARGETS.each do |relative|
  path = File.join(ROOT, relative)
  next unless File.read(path).include?(OBSOLETE_OPTION_CONTINUE_REPLY)

  add_error(errors, path, 1, '仍包含 Option 不触发后的冗余继续确认')
end


missing_scenario_two = MANUAL_PLAN_SCENARIO_TWO_REQUIREMENTS.reject do |token|
  routing_cases.include?(token)
end
unless missing_scenario_two.empty?
  add_error(errors, routing_cases_path, 1, "真实验收场景 2 缺少：#{missing_scenario_two.join('、')}")
end


(PLAN_BEHAVIOR_SKILL_TARGETS + PLAN_BEHAVIOR_DOC_TARGETS).uniq.each do |relative|
  path = File.join(ROOT, relative)
  content = File.read(path)
  obsolete = OBSOLETE_UNCONDITIONAL_EXECUTION_GATES.select { |token| content.include?(token) }
  next if obsolete.empty?

  add_error(errors, path, 1, "仍包含宿主已授权执行后的重复确认：#{obsolete.join('、')}")
end


missing_scenario_three = MANUAL_PLAN_SCENARIO_THREE_REQUIREMENTS.reject do |token|
  routing_cases.include?(token)
end
unless missing_scenario_three.empty?
  add_error(errors, routing_cases_path, 1, "真实验收场景 3 缺少：#{missing_scenario_three.join('、')}")
end

if errors.empty?
  puts "PASS workflow output format: #{TARGETS.length} Skills checked"
  exit 0
end

puts "FAIL workflow output format: #{errors.length} issue(s)"
puts errors
exit 1
