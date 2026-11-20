class Task < ApplicationRecord
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, default: :medium, validate: { allow_nil: true }
  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, default: :not_started,
    validate: { message: "は未着手・進行中・完了から選んでください" }

  validates :title, presence: { message: "を入力してください" }
  # 優先度が未設定の旧データは、その値を保ったまま状態を変更できる。
  validates :priority, presence: true, if: -> { new_record? || will_save_change_to_priority? }

  def self.search(filters)
    tasks = all
    if (title = filters[:q].to_s.strip).present?
      tasks = tasks.where("title LIKE ? ESCAPE '!'", "%#{sanitize_sql_like(title, "!")}%")
    end
    tasks = tasks.where(priority: filters[:priority]) if priorities.key?(filters[:priority])
    case filters[:completion]
    when "complete"   then tasks = tasks.completed
    when "incomplete" then tasks = tasks.where(status: [:not_started, :in_progress])
    end

    column = filters[:sort] == "due_date" ? :due_date : :scheduled_at
    tasks.order(arel_table[column].asc.nulls_last, :id)
  end

  def self.human_attribute_name(attr, options = {})
    return "タスク名" if attr.to_s == "title"
    return "状態" if attr.to_s == "status"
    super
  end
end
