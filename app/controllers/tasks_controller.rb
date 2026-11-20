
class TasksController < ApplicationController
  def new
    @task = Task.new(scheduled_at: Time.current.change(sec: 0))
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      redirect_to new_task_path, notice: "タスクを登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    task = Task.find(params[:id])
    status = params.expect(task: [:status])[:status]
    if Task.statuses.key?(status)
      # 旧データには優先度がない場合もあるため、検証済みの状態だけを保存する。
      task.update_attribute!(:status, status)
      redirect_to root_path, status: :see_other, notice: "予定の状態を変更しました"
    else
      redirect_to root_path, status: :see_other, notice: "状態は未着手・進行中・完了から選んでください"
    end
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
