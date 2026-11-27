require "test_helper"

class TopTasksTest < ActionDispatch::IntegrationTest
  test "Top groups today's plans using their scheduled time in Japan" do
    # Midnight in Japan is still the previous day in UTC.
    travel_to Time.zone.local(2026, 11, 20, 0, 30) do
      now = Time.current
      started = Task.create!(title: "朝の体操", scheduled_at: now)
      upcoming = Task.create!(title: "食事の準備", scheduled_at: now + 1.hour)
      active = Task.create!(title: "早めに始めた掃除", scheduled_at: now + 2.hours, status: :in_progress)
      done = Task.create!(title: "終わった洗濯", scheduled_at: now, status: :completed)
      yesterday = Task.create!(title: "昨日の用事", scheduled_at: now - 1.hour)
      tomorrow = Task.create!(title: "明日の用事", scheduled_at: now + 1.day)

      get root_path

      assert_response :success
      assert_equal "not_started", started.reload.status
      assert_card_in "いま やること", started, active
      assert_card_in "このあとの予定", upcoming
      assert_card_in "終わったこと", done
      assert_select "#task_#{yesterday.id}, #task_#{tomorrow.id}", count: 0
    end
  end

  test "search combines title, priority and completion over all dates and sorts undated deadlines last" do
    common = { scheduled_at: 1.week.from_now, priority: :high, status: :not_started }
    no_deadline = Task.create!(**common, title: "買い物100% 未設定")
    later = Task.create!(**common, title: "買い物100% 今週", due_date: 3.days.from_now.to_date)
    earlier = Task.create!(**common, title: "買い物100% 期限切れ", due_date: Date.yesterday, status: :in_progress)
    done = Task.create!(**common, title: "買い物100% 済", status: :completed)
    Task.create!(**common, title: "買い物100% 優先度低", priority: :low)
    Task.create!(**common, title: "買い物100円")

    filters = { q: "買い物100%", priority: "high", sort: "due_date" }
    get root_path, params: filters.merge(completion: "incomplete")

    assert_response :success
    assert_equal [ earlier, later, no_deadline ].map { |task| "task_#{task.id}" },
      css_select(".task-card").map { |card| card["id"] }
    get root_path, params: filters.merge(completion: "complete")
    assert_equal [ "task_#{done.id}" ], css_select(".task-card").map { |card| card["id"] }

    get root_path, params: { q: "一致しないタスク名" }
    assert_select ".task-card", count: 0
    assert_match "条件に合う予定はありません", response.body
    assert_select "a[href=?]", root_path, text: "条件をクリア"
  end

  test "changing a plan's status moves its card and persists when Top is reopened" do
    travel_to Time.zone.local(2026, 11, 20, 9) do
      task = Task.create!(title: "昼ごはんの準備", scheduled_at: 3.hours.from_now)
      { in_progress: "いま やること", completed: "終わったこと", not_started: "このあとの予定" }.each do |status, heading|
        patch task_path(task), params: { task: { status: status } }
        assert_redirected_to root_path
        assert_equal status.to_s, task.reload.status
        get root_path
        assert_card_in heading, task
      end
    end
  end

  test "deleting one task returns to Top with the other task intact" do
    first = Task.create!(title: "削除する予定", scheduled_at: Time.current)
    other = Task.create!(title: "残す予定", scheduled_at: Time.current)

    get root_path
    assert_select "#task_#{first.id}" do
      assert_select "a[href=?]", task_path(first, from: "top") do
        assert_select "form, button, select, dialog", count: 0
      end
      assert_select "form[action=?] select[name=?]", task_path(first), "task[status]"
      assert_select "button[data-action=?]", "delete-dialog#open", text: "削除"
      assert_select "dialog" do
        assert_select "button[type=button][data-action=?]", "delete-dialog#cancel", text: "キャンセル"
        assert_select "form[action=?] input[name=_method][value=delete]", task_path(first)
      end
    end

    assert_difference("Task.count", -1) { delete task_path(first) }
    assert_redirected_to root_path
    follow_redirect!
    assert_match "予定を削除しました", response.body

    get root_path
    assert_select "#task_#{first.id}", count: 0
    assert_select "#task_#{other.id} a[href=?]", task_path(other, from: "top"), text: /残す予定/
  end

  test "status can change on old tasks with an unset priority without inventing a priority" do
    task = tasks(:one)
    assert_nil task.priority

    patch task_path(task), params: { task: { status: "completed" } }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", text: "予定の状態を変更しました"
    assert_predicate task.reload, :completed?
    assert_nil task.priority

    refute Task.new(title: "新しい予定", priority: nil).valid?
    assert task.update(priority: :high)
    refute task.update(priority: nil)
    assert_equal "high", task.reload.priority
  end

  test "invalid status and invalid task data leave the saved status intact and explain the error" do
    task = Task.create!(title: "掃除")
    patch task_path(task), params: { task: { status: "unknown" } }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", text: /状態を変更できませんでした。.*未着手・進行中・完了/
    assert_predicate task.reload, :not_started?

    task.update_column(:title, nil)
    patch task_path(task), params: { task: { status: "completed" } }
    assert_redirected_to root_path
    follow_redirect!
    assert_select "[role=status]", text: /状態を変更できませんでした。.*タスク名/
    assert_predicate task.reload, :not_started?
  end

  private

  def assert_card_in(heading, *tasks)
    section = css_select("section > h2").find { |h2| h2.text.strip == heading }&.parent
    assert section, "#{heading}の表示領域がありません"
    tasks.each do |task|
      assert_select section, "#task_#{task.id} a[href=?]", task_path(task, from: "top"), text: /#{Regexp.escape(task.title)}/
      assert_select "#task_#{task.id}", count: 1
    end
  end
end
