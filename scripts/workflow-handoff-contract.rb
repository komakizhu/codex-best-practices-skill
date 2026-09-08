#!/usr/bin/env ruby
# frozen_string_literal: true

module WorkflowHandoffContract
  MIN_HANDOFF_COMMANDS = 3
  MAX_HANDOFF_COMMANDS = 4
  COMMAND = /\A\s*`[^`]+`\s*\z/
  HOST_ACTION = /(?:请|需要你|你可以|用户需要|选择|点击|打开|进入|切换|返回)[^。！？!?；;\n]{0,30}(?:宿主|Plan|Implement|return-to-execution)/
  NEGATED_ACTION_PREFIX = /(?:不会|不|无需|不需要|不要|没有|无|请勿|勿|禁止|不得|不能|不可)[^。！？!?；;\n]{0,12}\z/
  NEGATED_ACTION_WORDS = /(?:不会|不|无需|不需要|不要|没有|无|请勿|勿|禁止|不得|不能|不可)/
  FUTURE_ACTION_PREFIX = /(?:(?:下一步|接下来|之后|稍后|随后|以后)[^。！？!?；;\n]{0,8}(?:会|将)|(?:会|将))\s*\z/
  FUTURE_PROMISE = /(?:(?:下一步|接下来|之后|稍后|随后|以后)[^。！？!?；;\n]{0,12})?(?<!不)(?:将会|会|将)[^。！？!?；;\n]{0,8}(?:继续|开始|处理|执行|检查|读取|整理|验证|调查)/
  COMPLETION_PROMISE = /(?:
    (?:你|用户)[^。！？!?；;\n]{0,12}(?:确认|回复|选择)[^。！？!?；;\n]{0,12}(?:后|即可)[^。！？!?；;\n]{0,24}(?:Codex|Workflow)[^。！？!?；;\n]{0,12}(?:会|将|继续)
    |
    (?:请你|请|需要你)[^。！？!?；;\n]{0,12}(?:确认|回复|选择)[^。！？!?；;\n]{0,20}(?:继续|下一轮|后续|下一步)
  )/x
  WRITE_TOOL_NAME = /\A(?:FileChange|apply_patch|write_file|edit_file|replace_file|patch_file)\z/i

  def self.normalized(text)
    text.to_s.gsub("\r\n", "\n")
  end

  def self.command_blocks(text)
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

  def self.command_values(text)
    command_blocks(text).map { |block| block[:command].delete('`') }
  end

  def self.positive_host_action?(text)
    normalized(text).lines.any? do |line|
      line.to_enum(:scan, HOST_ACTION).any? do
        match = Regexp.last_match
        prefix = line[0...match.begin(0)]
        action = match[0]
        !prefix.match?(NEGATED_ACTION_PREFIX) &&
          !prefix.match?(FUTURE_ACTION_PREFIX) &&
          !action.match?(NEGATED_ACTION_WORDS)
      end
    end
  end

  def self.positive_host_action_in_lines?(lines)
    positive_host_action?(lines.map { |_, line| line }.join("\n"))
  end

  def self.write_tool?(event)
    %w[tool_name tool action].any? do |key|
      event[key].to_s.match?(WRITE_TOOL_NAME)
    end
  end
end
