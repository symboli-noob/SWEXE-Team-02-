class Task < ApplicationRecord
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, default: :medium, validate: true
  enum :status, { not_started: 0, in_progress: 1, completed: 2 }, default: :not_started, validate: true

  validates :title, presence: { message: "を入力してください" }
  validates :priority, presence: true

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
    super
  end
end
