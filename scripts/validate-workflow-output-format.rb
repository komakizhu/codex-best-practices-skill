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
    'native Plan 必须先交接请求再等待结果' => [
      'a filled `Plan 请求`',
      'current conversation',
      'Do not first ask the user to say `Plan 已完成`',
      '确认计划，执行'
    ]
  },
  'task-router' => {
    'user-run Plan 必须区分请求、结果和执行确认' => [
      'showing the filled request completes only the request handoff',
      'real native Plan result is observable in the current conversation',
      'do not ask the user to paste or upload it again',
      'A bare `Plan 已完成` is not evidence'
    ]
  }
}.freeze

ROUTING_CASE_REQUIREMENTS = [
  '当前会话手动进入 Plan',
  'Output the filled Plan request before any `Plan 已完成` prompt',
  'Treat the visible native result as returned, do not request a second copy',
  '当前会话没有真实 Plan 结果'
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

  if lines.any? { |_, line| line.match?(/怎么回复|请确认|请回复|切换/) }
    reply_items = lines.select { |_, line| line.strip.start_with?('- ') }
    if reply_items.length < 2
      add_error(errors, path, block[:start_line], '包含回复/切换动作的卡片必须把选项拆成至少两条列表项')
    end

    reply_items.each do |line_number, line|
      command_count = line.scan(/`[^`]+`/).length
      add_error(errors, path, line_number, '每个回复列表项只能包含一个口令') unless command_count == 1
      add_error(errors, path, line_number, '回复列表项不能用分号串联多个动作') if line.include?('；')
    end
  end
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

SEMANTIC_REQUIREMENTS.each do |skill, requirements|
  path = File.join(ROOT, '.agents', 'skills', skill, 'SKILL.md')
  content = File.read(path)

  requirements.each do |label, tokens|
    missing = tokens.reject { |token| content.include?(token) }
    next if missing.empty?

    add_error(errors, path, 1, "#{label} 缺少语义契约：#{missing.join('、')}")
  end
end

routing_cases_path = File.join(ROOT, '.agents', 'skills', 'task-router', 'references', 'routing-cases.md')
routing_cases = File.read(routing_cases_path)
missing_routing_cases = ROUTING_CASE_REQUIREMENTS.reject { |token| routing_cases.include?(token) }
unless missing_routing_cases.empty?
  add_error(errors, routing_cases_path, 1, "手动 Plan 验收案例缺少：#{missing_routing_cases.join('、')}")
end

if errors.empty?
  puts "PASS workflow output format: #{TARGETS.length} Skills checked"
  exit 0
end

puts "FAIL workflow output format: #{errors.length} issue(s)"
puts errors
exit 1
