require "test_helper"

class TaskDetailTest < ActionDispatch::IntegrationTest
  test "the three Top sections open the selected record even when task names match" do
    travel_to Time.zone.local(2026, 11, 27, 9) do
      schedules = [
        [ "いま やること", 1.hour.ago, :not_started, "玄関の袋を持つ" ],
        [ "このあとの予定", 2.hours.from_now, :not_started, "台所の袋を持つ" ],
        [ "終わったこと", 2.hours.ago, :completed, "庭の袋を持つ" ]
      ]
      plans = schedules.map do |heading, time, status, memo|
        [ heading, Task.create!(title: "ごみを出す", scheduled_at: time, status: status, description: memo) ]
      end

      plans.each do |heading, task|
        get root_path
        section = css_select("section > h2").find { |h2| h2.text.strip == heading }.parent
        link = assert_select(section, "a[href=?]", task_path(task, from: "top")).first
        assert_match task.title, link.text
        assert_select link, "time", text: task.scheduled_at.strftime("%-H:%M")

        get link["href"]
        assert_response :success
        assert_select "h2", text: task.title
        assert_detail_field "メモ", task.description
        assert_select "a[href=?]", root_path, text: /戻る/
      end
    end
  end

  test "details from the list show saved fields, fallback values, and a way back to the list" do
    task = Task.create!(
      title: "買い物", description: "牛乳とパン", priority: :high, status: :in_progress,
      scheduled_at: Time.zone.local(2026, 11, 27, 14, 15), due_date: Date.new(2026, 11, 28),
      created_at: Time.zone.local(2026, 11, 23, 8, 30), updated_at: Time.zone.local(2026, 11, 24, 10, 45)
    )
    get tasks_path
    link = assert_select("a[href=?]", task_path(task), text: /詳細/).first
    get link["href"]
    assert_response :success
    assert_select "h2", text: task.title
    assert_select "time", text: /2026年11月27日/
    assert_select "time", text: /14:15/
    assert_detail_field "メモ", "牛乳とパン"
    assert_detail_field "状態", "進行中"
    assert_detail_field "優先度", "高"
    assert_detail_field "期限", /2026年11月28日/
    assert_detail_field "作成日時", /2026年11月23日.*08:30/
    assert_detail_field "最終更新日時", /2026年11月24日.*10:45/
    assert_detail_field "写真", "写真なし"
    assert_detail_field "場所", "未設定"
    assert_detail_field "通知", "未設定"
    back_link = assert_select("a[href=?]", tasks_path, text: /戻る/).first
    get back_link["href"]
    assert_select "h1", text: "タスク一覧"

    get task_path(tasks(:one))
    assert_response :success
    assert_detail_field "優先度", "未設定"
    assert_detail_field "メモ", "未設定"
  end

  test "completing a task from its detail updates only that task and stays complete after reloading" do
    travel_to Time.zone.local(2026, 11, 27, 9) do
      selected = Task.create!(title: "花に水をあげる", scheduled_at: Time.current)
      other = Task.create!(title: selected.title, scheduled_at: Time.current)

      get task_path(selected, from: "top")
      form = assert_select("form[action=?]", task_path(selected)).first
      assert_select form, "input[name=_method][value=patch]"
      assert_select form, "input[name=?][value=completed]", "task[status]"
      assert_select form, "button", text: "完了にする"
      patch form["action"], params: { task: { status: "completed" } }
      assert_redirected_to root_path
      follow_redirect!
      get root_path
      done = css_select("section > h2").find { |h2| h2.text.strip == "終わったこと" }.parent
      assert_select done, "#task_#{other.id}", count: 0
      link = assert_select(done, "#task_#{selected.id} a[href=?]", task_path(selected, from: "top")).first
      assert_predicate selected.reload, :completed?
      assert_predicate other.reload, :not_started?

      get link["href"]
      assert_detail_field "状態", "完了"
      assert_select "button", text: "完了にする", count: 0
    end
  end

  private

  def assert_detail_field(label, expected)
    term = assert_select("dt", text: label, count: 1).first
    value = term.next_element.text.squish
    assert_match expected, value
  end
end
