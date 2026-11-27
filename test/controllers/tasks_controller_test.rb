
require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  test "edit shows saved values and saves a changed deadline" do
    task = Task.create!(title: "通院", description: "診察券", priority: :high,
      scheduled_at: Time.zone.local(2026, 11, 27, 9), due_date: Date.new(2026, 11, 27))
    get task_path(task)
    assert_select "a[href=?]", edit_task_path(task), text: "編集"
    get edit_task_path(task)
    assert_response :success
    assert_select "input[name='task[title]'][value='通院']"
    assert_select "textarea[name='task[description]']", text: "診察券"
    assert_select "input[name='task[scheduled_at]'][value^='2026-11-27T09:00']"
    assert_select "input[name='task[due_date]'][value='2026-11-27']"
    assert_select "option[selected][value=high]"

    previous = task.attributes.except("updated_at", "due_date")
    patch task_path(task), params: { task: { due_date: "2026-11-28" } }
    assert_redirected_to task_path(task)
    follow_redirect!
    deadline = assert_select("dt", text: "期限", count: 1).first
    assert_select deadline.next_element, "time[datetime=?]", "2026-11-28", text: "2026年11月28日"
    assert_equal previous, task.reload.attributes.except("updated_at", "due_date")
  end

  test "invalid edits preserve saved data and can be corrected" do
    task = Task.create!(title: "通院", description: "診察券")
    patch task_path(task), params: { task: { title: "", description: "持ち物" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /タスク名/
    assert_select "textarea", text: "持ち物"
    assert_equal [ "通院", "診察券" ], [ task.reload.title, task.description ]
    patch task_path(task), params: { task: { title: "受診", description: "持ち物" } }
    assert_redirected_to task_path(task)
    assert_equal "受診", task.reload.title
  end

  test "should get new" do
    get new_task_url
    assert_response :success
  end

  test "should create task" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: {
        task: {
          title: "買い物",
          description: "牛乳を買う",
          due_date: Date.current,
          priority: "high"
        }
      }
    end

    assert_redirected_to tasks_url
  end

  test "should not create task without title" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {
        task: {
          title: "",
          priority: "medium"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
