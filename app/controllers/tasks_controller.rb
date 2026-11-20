
class TasksController < ApplicationController
  def new
    @task = Task.new(scheduled_at: Time.current.change(sec: 0))
  end
  def index
    @tasks = Task.order(created_at: :desc)
  end

  def show
    @task = Task.find(params[:id])
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to tasks_path, notice: "タスクを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    task = Task.find(params[:id])
    status = params.expect(task: [:status])[:status]
    message = if task.update(status: status)
      "予定の状態を変更しました"
    else
      "予定の状態を変更できませんでした。#{task.errors.full_messages.join("、")}"
    end
    redirect_to root_path, status: :see_other, notice: message
  end

  def destroy
    Task.find(params[:id]).destroy!
    redirect_to root_path, status: :see_other, notice: "予定を削除しました"
  end

  private

  def task_params
    params.require(:task).permit(:title, :description, :scheduled_at, :due_date, :priority)
  end
end
