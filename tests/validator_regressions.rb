#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'

require_relative '../scripts/validate-workflow-output-format'
require_relative '../scripts/validate-workflow-continuity'

class ValidatorRegressionsTest < Minitest::Test
  def reply_lines(text)
    text.lines.map.with_index(1) { |line, number| [number, line.chomp] }
  end

  def command_errors(text)
    errors = []
    validate_reply_commands(errors, 'probe.md', reply_lines(text))
    errors
  end

  def test_valid_command_block_is_checked_when_heading_has_a_colon
    text = <<~MARKDOWN
      **怎么回复：**

      `确认`

      > 你确认后，Codex 会继续当前步骤。

      `继续聊聊`

      > 你想继续讨论。Codex 会保留当前内容。

      `取消`

      > 你要停止当前任务。Codex 不会修改文件。
    MARKDOWN

    assert_empty command_errors(text)
  end

  def test_missing_command_explanation_is_rejected
    text = <<~MARKDOWN
      **怎么回复：**

      `确认`
    MARKDOWN

    assert command_errors(text).any? { |error| error.include?('每个口令后') }
  end

  def test_missing_blank_line_between_command_and_explanation_is_rejected
    text = <<~MARKDOWN
      **怎么回复：**

      `确认`
      > 你确认后，Codex 会继续当前步骤。
    MARKDOWN

    assert command_errors(text).any? { |error| error.include?('中间空一行') }
  end

  def test_missing_blockquote_explanation_is_rejected
    text = <<~MARKDOWN
      **怎么回复：**

      `确认`

      你确认后，Codex 会继续当前步骤。
    MARKDOWN

    assert command_errors(text).any? { |error| error.include?('说明必须以 `> ` 开头') }
  end

  def test_list_wrapped_command_is_rejected_without_rejecting_body_lists
    text = <<~MARKDOWN
      **怎么回复：**

      - `确认`

      > 你确认后，Codex 会继续当前步骤。
    MARKDOWN

    errors = command_errors(text)
    assert errors.any? { |error| error.include?('列表符') }
    refute errors.any? { |error| error.include?('正文') }
  end

  def test_body_list_with_inline_code_is_not_treated_as_a_command
    text = <<~MARKDOWN
      **怎么回复：**

      `确认`

      > 你确认后，Codex 会继续当前步骤。

      `继续聊聊`

      > 你想继续讨论。Codex 会保留当前内容。

      `取消`

      > 你要停止当前任务。Codex 不会修改文件。

      说明：
      - `FileChange` 仍然属于禁止动作。
    MARKDOWN

    assert_empty command_errors(text)
  end

  def test_execution_alias_cannot_be_displayed_as_a_second_choice
    text = <<~MARKDOWN
      **怎么回复：**

      `确认计划，执行`

      > 你授权 Codex 实施当前 Plan。

      `执行`

      > 你用简写授权 Codex 实施当前 Plan。

      `继续聊聊`

      > 你想继续讨论，Codex 不会修改文件。

      `取消`

      > 你要停止当前任务，Codex 不会修改文件。
    MARKDOWN

    assert command_errors(text).any? { |error| error.include?('隐藏输入别名') }
  end

  def test_handoff_requires_at_least_three_commands
    text = <<~MARKDOWN
      **结论：调查还没有结束。**

      **已完成：**
      Codex 已经核对了当前证据。

      **下一步：**
      你选择后，Codex 会继续调查；当前不会修改文件。

      **怎么回复：**
      `已就绪`

      > 你已经准备好。Codex 会继续调查。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('至少需要 3 个') }
  end

  def test_handoff_rejects_duplicate_commands
    text = <<~MARKDOWN
      **结论：调查还没有结束。**

      **已完成：**
      Codex 已经核对了当前证据。

      **下一步：**
      你选择后，Codex 会继续调查；当前不会修改文件。

      **怎么回复：**
      `已就绪`

      > 你已经准备好。Codex 会继续调查。

      `继续聊聊`

      > 你想继续讨论。Codex 会保留当前证据。

      `取消`

      > 你要停止当前任务。Codex 不会修改文件。

      `取消`

      > 你要停止当前任务。Codex 不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('重复') }
  end

  def test_handoff_rejects_more_than_four_commands
    text = <<~MARKDOWN
      **结论：调查还没有结束。**

      **已完成：**
      Codex 已经核对了当前证据。

      **下一步：**
      你选择后，Codex 会继续调查；当前不会修改文件。

      **怎么回复：**
      `已就绪`

      > 你已经准备好。Codex 会继续调查。

      `补充证据`

      > 你要补充证据。Codex 会继续只读调查。

      `确认路由`

      > 你确认当前路线。Codex 会进入下一阶段。

      `继续聊聊`

      > 你想继续讨论。Codex 会保留当前证据。

      `取消`

      > 你要停止当前任务。Codex 不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('最多需要 4 个') }
  end

  def test_negative_host_action_phrase_does_not_satisfy_handoff
    text = <<~MARKDOWN
      **结论：证据已经收集。**

      **已完成：**
      Codex 已经核对了当前文本。

      **下一步：**
      Codex 不会进入 Plan，也不会使用宿主动作；本轮不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('口令或明确的宿主操作') }
  end

  def test_negated_host_action_with_direct_command_word_does_not_satisfy_handoff
    text = <<~MARKDOWN
      **结论：Plan 请求已经整理。**

      **已完成：**
      Codex 已经准备好请求内容。

      **下一步：**
      Codex 请不要进入 Plan；本轮不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('口令或明确的宿主操作') }
  end

  def test_future_or_prohibited_host_action_does_not_satisfy_handoff
    [
      'Codex 下一步会进入 Plan。',
      'Codex 请勿进入 Plan。',
      'Codex 禁止进入 Plan。'
    ].each do |sentence|
      text = <<~MARKDOWN
        **结论：Plan 请求已经整理。**

        **已完成：**
        Codex 已经准备好请求内容。

        **下一步：**
        #{sentence} 本轮不会修改文件。
      MARKDOWN

      errors = validate_visible_reply({ 'text' => text }, 0)
      assert errors.any? { |error| error.include?('口令或明确的宿主操作') }, sentence
    end
  end

  def test_positive_host_action_is_accepted_as_the_next_step
    text = <<~MARKDOWN
      **结论：当前需要宿主进入 Plan。**

      **已完成：**
      Codex 已经准备好完整的 Plan 请求。

      **下一步：**
      你打开宿主的 Plan 模式并粘贴下面的请求；真实 Plan 结果出现前不会修改文件。
    MARKDOWN

    assert_empty validate_visible_reply({ 'text' => text }, 0)
  end

  def test_next_actor_without_an_action_is_rejected
    text = <<~MARKDOWN
      **结论：调查结果已经整理。**

      **已完成：**
      Codex 已经核对了当前证据。

      **下一步：**
      你；本轮不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('下一步由谁执行') }
  end

  def test_inline_command_without_standalone_command_is_rejected
    text = <<~MARKDOWN
      **结论：调查还没有结束。**

      请回复 `已就绪`，Codex 会继续调查；当前不会修改文件。
    MARKDOWN

    errors = []
    validate_reply_commands(errors, 'memory.md', reply_lines(text))
    assert errors.any? { |error| error.include?('独占一段') }
  end

  def test_handoff_like_block_without_command_or_host_action_is_rejected
    Tempfile.create(['missing-handoff', '.md']) do |file|
      file.write(<<~MARKDOWN)
        ```markdown
        **结论：调查结果已经整理。**

        **已完成：**
        Codex 已经核对了当前证据。

        **下一步：**
        Codex 不会进入 Plan，也不会使用宿主动作；本轮没有用户需要执行的动作。
        ```
      MARKDOWN
      file.flush

      block = fenced_blocks(file.path).first
      errors = []
      validate_block(errors, file.path, block)
      assert errors.any? { |error| error.include?('交接回复必须包含独立口令或明确宿主动作') }
    end
  end

  def test_summary_style_handoff_without_standard_commands_is_rejected
    Tempfile.create(['summary-without-handoff', '.md']) do |file|
      file.write(<<~MARKDOWN)
        ```markdown
        **结论：任务已完成。**

        **状态：**
        调查已经结束。

        **后续动作：**
        Codex 会等待后续安排；本轮不会修改文件。
        ```
      MARKDOWN
      file.flush

      block = fenced_blocks(file.path).first
      errors = []
      validate_block(errors, file.path, block)
      assert errors.any? { |error| error.include?('交接回复必须包含独立口令或明确宿主动作') }
    end
  end

  def test_handoff_without_a_recognized_summary_still_requires_commands
    Tempfile.create(['handoff-without-summary', '.md']) do |file|
      file.write(<<~MARKDOWN)
        ```markdown
        调查结果已经整理。

        **下一步：**
        Codex 会等待后续安排；本轮不会修改文件。
        ```
      MARKDOWN
      file.flush

      block = fenced_blocks(file.path).first
      errors = []
      validate_block(errors, file.path, block)
      assert errors.any? { |error| error.include?('交接回复必须包含独立口令或明确宿主动作') }
    end
  end

  def test_standalone_conclusion_block_is_checked_for_handoff
    Tempfile.create(['conclusion-only', '.md']) do |file|
      file.write(<<~MARKDOWN)
        ```markdown
        **结论：调查结果已经整理。**
        ```
      MARKDOWN
      file.flush

      block = fenced_blocks(file.path).first
      errors = []
      validate_block(errors, file.path, block)
      assert errors.any? { |error| error.include?('交接回复必须包含独立口令或明确宿主动作') }
    end
  end

  def test_progress_reply_without_actual_continuation_is_rejected
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'progress',
          'continues' => false,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：调查结果已经整理。**

            **已完成：**
            Codex 已经核对了当前证据。

            **下一步：**
            Codex 下一步会继续调查。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('progress_without_continuation:') }
  end

  def test_progress_future_promise_is_rejected_even_when_continuation_flags_are_set
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'progress',
          'continues' => true,
          'turn_end' => false,
          'text' => <<~MARKDOWN
            **结论：调查仍在进行。**

            **已完成：**
            Codex 已经核对了当前证据。

            **下一步：**
            Codex 下一步会继续读取配置；当前不会修改文件。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('progress_future_promise:') }
    assert errors.any? { |error| error.start_with?('progress_without_follow_up:') }
  end

  def test_progress_reply_requires_an_explicit_open_turn
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'progress',
          'continues' => true,
          'text' => <<~MARKDOWN
            **结论：调查仍在进行。**

            **已完成：**
            Codex 已经核对了当前证据。

            **下一步：**
            Codex 正在继续读取配置；当前不会修改文件。
          MARKDOWN
        },
        { 'actor' => 'tool', 'tool_name' => 'ReadFile', 'text' => 'read-only result' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('progress_without_continuation:') }
  end

  def test_waiting_reply_without_handoff_is_rejected
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'waiting',
          'awaits_user' => true,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：调查暂时停在这里。**

            **已完成：**
            Codex 已经核对了当前证据。

            **下一步：**
            你需要决定后续处理方式。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('waiting_missing_handoff:') }
  end

  def test_complete_reply_can_end_without_an_extra_confirmation
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'complete',
          'terminal' => true,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：任务已完成。**

            **已完成：**
            Codex 已经完成修改和验证。

            **下一步：**
            Codex 已经交付结果，本任务到此结束。
          MARKDOWN
        }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_complete_reply_requires_a_nonempty_completed_scope
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'complete',
          'terminal' => true,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：任务已完成。**

            **已完成：**

            **下一步：**
            Codex 已经交付结果，本任务到此结束。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.include?('没有说明已完成范围') }
  end

  def test_complete_reply_cannot_promise_more_work_after_confirmation
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'complete',
          'terminal' => true,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：任务已完成。**

            **已完成：**
            Codex 已经完成修改和验证。

            **下一步：**
            你确认后，Codex 会继续处理新的修改。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('complete_future_promise:') }
  end

  def test_complete_reply_cannot_ask_for_a_new_round_confirmation
    case_data = {
      'events' => [
        {
          'actor' => 'assistant',
          'channel' => 'main',
          'reply_state' => 'complete',
          'terminal' => true,
          'turn_end' => true,
          'text' => <<~MARKDOWN
            **结论：任务已完成。**

            **已完成：**
            Codex 已经完成修改和验证。

            **下一步：**
            请你确认是否继续下一轮；本任务当前已经结束。
          MARKDOWN
        }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('complete_future_promise:') }
  end

  def test_tool_file_change_is_checked_as_a_write_event
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个小功能' },
        { 'actor' => 'tool', 'tool_name' => 'FileChange', 'text' => 'tool wrote a file' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_route_confirmation:') }
  end

  def test_external_result_return_requires_main_channel
    case_data = {
      'events' => [
        { 'actor' => 'user', 'text' => '$engineering-workflow 调用外部 Skill' },
        { 'actor' => 'assistant', 'return_from' => 'external', 'channel' => 'side', 'text' => 'external result' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('reply_channel_invalid:') }
  end

  def test_side_handoff_return_requires_main_channel
    case_data = {
      'events' => [
        { 'actor' => 'user', 'text' => '$engineering-workflow 继续处理当前任务' },
        { 'actor' => 'side', 'side_handoff' => true, 'text' => 'SIDE-HANDOFF: result' },
        { 'actor' => 'assistant', 'side_handoff_return' => true, 'channel' => 'side', 'text' => 'side result returned' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('reply_channel_invalid:') }
  end

  def test_nested_plan_request_fence_is_not_validated_as_a_second_output_card
    Tempfile.create(['nested-fences', '.md']) do |file|
      file.write(<<~MARKDOWN)
        ````markdown
        **结论：请把 Plan 请求提交到宿主。**

        **Plan 请求：**

        **任务目标：**
        目标

        **已确认的 RCA/证据：**
        证据

        **范围：**
        范围

        **非目标：**
        非目标

        **约束：**
        约束

        **验收与验证：**
        验收

        ```text
        请只制定 native Plan。
        ```
        ````
      MARKDOWN
      file.flush

      blocks = fenced_blocks(file.path)
      assert_equal 1, blocks.length
      assert_equal 4, blocks.first[:fence_length]
      assert_equal 'markdown', blocks.first[:language]
    end
  end

  def test_formal_five_item_brief_does_not_need_duplicate_common_headings
    text = <<~MARKDOWN
      **目标：把按钮文案改成保存。**

      **当前上下文/证据：**
      Codex 已整理用户提出的按钮文案要求。

      **约束与授权：**
      当前只等待 Brief 确认，不修改文件。

      **范围/非目标：**
      只调整按钮文案，不调整保存逻辑。

      **验收标准/待确认项：**
      下一步由你确认摘要；你确认后，Codex 会展示 Route；按钮显示保存。

      请确认这份任务摘要。

      `确认`

      > 你同意这份任务摘要。Codex 接下来会展示 Route，不会修改文件。

      `修改：请把……改成……`

      > 你要修改摘要。Codex 会重新整理 Brief，不会修改文件。

      `先聊一聊`

      > 你暂时不确认摘要。Codex 会继续讨论，不会修改文件。

      `取消`

      > 你要停止任务。Codex 不会继续处理或修改文件。
    MARKDOWN

    assert_empty validate_visible_reply({ 'text' => text }, 0)
  end

  def test_formal_brief_requires_next_actor_in_the_fifth_item
    text = <<~MARKDOWN
      **目标：整理任务。**

      **当前上下文/证据：**
      Codex 已经整理现有事实。

      **约束与授权：**
      当前不会修改文件。

      **范围/非目标：**
      只定义当前任务。

      **验收标准/待确认项：**
      验收完成后展示 Route，但授权前不会修改文件。

      请确认这份任务摘要。

      `确认`

      > 你同意这份任务摘要。Codex 接下来会展示 Route，不会修改文件。

      `修改：请把……改成……`

      > 你要修改摘要。Codex 会重新整理 Brief，不会修改文件。

      `先聊一聊`

      > 你暂时不确认摘要。Codex 会继续讨论，不会修改文件。

      `取消`

      > 你要停止任务。Codex 不会修改文件。
    MARKDOWN

    errors = validate_visible_reply({ 'text' => text }, 0)
    assert errors.any? { |error| error.include?('下一步执行者') }
  end

  def test_write_before_route_confirmation_is_reported_by_event_order
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修复这个问题' },
        { 'actor' => 'assistant', 'text' => 'route card' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_route_confirmation:') }
  end

  def test_brief_confirmation_is_required_before_route_can_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'brief' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-brief 请整理这个任务' },
        { 'actor' => 'assistant', 'text' => 'brief card' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_brief_confirmation:') }
  end

  def test_discussion_can_resume_previous_small_authorization_after_reconfirmation
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'brief' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-brief 请整理这个任务' },
        { 'actor' => 'assistant', 'text' => 'brief card' },
        { 'actor' => 'user', 'text' => '先聊一聊' },
        { 'actor' => 'assistant', 'text' => 'discussion card' },
        { 'actor' => 'user', 'text' => '整理 brief' },
        { 'actor' => 'user', 'text' => '确认' },
        { 'actor' => 'assistant', 'text' => 'route card' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_discussion_resume_preserves_confirmed_small_route_authorization
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个小功能' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '继续聊聊' },
        { 'actor' => 'assistant', 'text' => 'discussion card' },
        { 'actor' => 'user', 'text' => '恢复执行' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_material_scope_change_requires_route_reconfirmation
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个小功能' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '继续聊聊' },
        { 'actor' => 'user', 'text' => '范围发生实质改变' },
        { 'actor' => 'user', 'text' => '整理 brief' },
        { 'actor' => 'assistant', 'text' => 'brief card' },
        { 'actor' => 'user', 'text' => '确认' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_route_confirmation:') }
  end

  def test_plan_only_write_requires_native_plan_and_execution_authorization
    case_data = {
      'workflow' => { 'mode' => 'plan-only', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 只做计划' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_without_execution_authorization:') }
  end

  def test_execution_confirmation_before_native_plan_cannot_unlock_a_write
    case_data = {
      'workflow' => { 'mode' => 'plan-only', 'size' => 'medium', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 只做计划' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '确认计划，执行' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('execution_before_native_plan:') }
  end

  def test_medium_plan_result_still_requires_execution_authorization
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'medium', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个中型功能' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'native_plan' => true, 'text' => 'native plan' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_without_execution_authorization:') }
  end

  def test_host_implement_action_authorizes_visible_native_plan
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'medium', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个中型功能' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'native_plan' => true, 'text' => 'native plan' },
        { 'actor' => 'assistant', 'host_action' => 'Implement', 'text' => 'host returned to execution' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_explicit_plan_request_for_small_task_requires_native_plan
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 请先给我一个 Plan 再实施' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_without_execution_authorization:') }
  end

  def test_large_non_bug_does_not_require_rca
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'large', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 迁移这个数据格式' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'native_plan' => true, 'text' => 'native plan' },
        { 'actor' => 'user', 'text' => '确认计划，执行' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_large_bug_requires_confirmed_root_cause_before_plan_and_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'large', 'bug' => true, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修复这个 Large Bug' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'root_cause_confirmed' => true, 'text' => 'RCA card' },
        { 'actor' => 'assistant', 'native_plan' => true, 'text' => 'native plan' },
        { 'actor' => 'user', 'text' => '确认计划，执行' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_internal_rca_returns_to_confirmed_route_without_requiring_a_new_brief
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => true, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修复这个 Bug' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'root_cause_confirmed' => true, 'text' => 'RCA findings returned to Route' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_direct_rca_requires_the_returned_brief_to_be_confirmed
    case_data = {
      'workflow' => { 'mode' => 'check-only', 'size' => 'small', 'bug' => true, 'stage' => 'rca' },
      'events' => [
        { 'actor' => 'user', 'text' => '$rca-analyze 这个 Bug 先找根因' },
        { 'actor' => 'assistant', 'root_cause_confirmed' => true, 'text' => 'RCA findings' },
        { 'actor' => 'user', 'text' => '整理 brief' },
        { 'actor' => 'assistant', 'text' => 'brief handoff' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_brief_confirmation:') }
  end

  def test_option_preference_without_adoption_does_not_authorize_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 比较两个方案' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '进入 option' },
        { 'actor' => 'user', 'text' => '我偏好方案 A' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_before_option_selection:') }
  end

  def test_adopted_option_returns_to_confirmed_small_route
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 比较两个方案' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '进入 option' },
        { 'actor' => 'user', 'text' => '采用 A' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_explicit_alternative_option_is_an_adoption_not_a_preference
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 比较两个方案' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'user', 'text' => '进入 option' },
        { 'actor' => 'user', 'text' => '采用其他方向：保留现有接口' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_legacy_comparison_conclusion_input_still_ends_without_granting_write
    case_data = {
      'workflow' => { 'mode' => 'check-only', 'size' => 'small', 'bug' => false, 'stage' => 'option' },
      'events' => [
        { 'actor' => 'user', 'text' => '只保留比较结果' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_after_terminal:') }
  end

  def test_legacy_return_to_plan_input_preserves_the_plan_gate
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'option', 'route_confirmed' => true },
      'events' => [
        { 'actor' => 'user', 'text' => '回到 Plan' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_without_execution_authorization:') }
  end

  def test_execution_alias_authorizes_only_after_a_visible_native_plan
    case_data = {
      'workflow' => { 'mode' => 'plan-only', 'size' => 'medium', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 只做计划' },
        { 'actor' => 'user', 'text' => '确认路由' },
        { 'actor' => 'assistant', 'native_plan' => true, 'text' => 'native plan' },
        { 'actor' => 'user', 'text' => '执行' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    assert_empty validate_conversation(case_data)
  end

  def test_terminal_choice_blocks_later_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'implementation', 'route_confirmed' => true },
      'events' => [
        { 'actor' => 'user', 'text' => '只保留方案' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_after_terminal:') }
  end

  def test_legacy_read_only_conclusion_input_still_ends_without_granting_write
    case_data = {
      'workflow' => { 'mode' => 'check-only', 'size' => 'small', 'bug' => true, 'stage' => 'rca' },
      'events' => [
        { 'actor' => 'user', 'text' => '只保留结论' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_after_terminal:') }
  end

  def test_cancelled_task_blocks_later_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'implementation', 'route_confirmed' => true },
      'events' => [
        { 'actor' => 'user', 'text' => '取消' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_after_cancel:') }
  end

  def test_side_handoff_does_not_resume_a_paused_write
    case_data = {
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'implementation', 'route_confirmed' => true },
      'events' => [
        { 'actor' => 'user', 'text' => '继续聊聊' },
        { 'actor' => 'side', 'side_handoff' => true, 'text' => 'SIDE-HANDOFF: result' },
        { 'actor' => 'assistant', 'write' => true, 'action' => 'FileChange', 'text' => 'write' }
      ]
    }

    errors = validate_conversation(case_data)
    assert errors.any? { |error| error.start_with?('write_during_discussion:') }
  end

  def test_expected_negative_reason_is_required_not_just_any_error
    case_data = {
      'name' => 'negative reason probe',
      'expected_errors' => ['write_during_discussion'],
      'workflow' => { 'mode' => 'implementation', 'size' => 'small', 'bug' => false, 'stage' => 'route' },
      'events' => [
        { 'actor' => 'user', 'text' => '$task-router 修改这个小功能' },
        { 'actor' => 'assistant', 'text' => 'malformed' }
      ]
    }

    refute_empty validate_fail_case(case_data)
  end
end
