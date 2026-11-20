module TopHelper
  def task_status_options
    { "未着手" => "not_started", "進行中" => "in_progress", "完了" => "completed" }
  end

  def task_priority_options
    { "高" => "high", "中" => "medium", "低" => "low" }
  end

  def top_date_label(date)
    "#{date.month}月#{date.day}日（#{%w[日 月 火 水 木 金 土][date.wday]}）"
  end
end
