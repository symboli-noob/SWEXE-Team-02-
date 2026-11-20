class TopController < ApplicationController
  def show
    @now = Time.current
    filters = params.permit(:q, :priority, :completion, :sort)

    if params[:history] == "1"
      @mode = :history
      @sections = [["完了した予定", Task.completed.order(updated_at: :desc, id: :desc)]]
    elsif params[:search] == "1" || filters.values.any?(&:present?)
      @mode = :search
      @sections = [["検索結果", Task.search(filters)]]
    else
      @mode = :today
      today = Task.where(scheduled_at: @now.all_day).order(:scheduled_at, :id)
      finished, pending = today.partition(&:completed?)
      current, upcoming = pending.partition { |task| task.in_progress? || task.scheduled_at <= @now }
      @sections = [["いま やること", current], ["このあとの予定", upcoming], ["終わったこと", finished]]
    end
  end
end
