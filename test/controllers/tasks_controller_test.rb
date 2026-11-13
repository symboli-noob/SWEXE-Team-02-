
require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
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

    assert_redirected_to new_task_url
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
