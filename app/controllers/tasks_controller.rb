
class TasksController < ApplicationController
  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to new_task_path, notice: "タスクを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def task_params
  params.require(:task).permit(:title, :description, :due_date, :priority)
  end
end
