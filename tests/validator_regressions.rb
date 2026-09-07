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

      说明：
      - `FileChange` 仍然属于禁止动作。
    MARKDOWN

    assert_empty command_errors(text)
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
