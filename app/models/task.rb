class Task < ApplicationRecord
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, default: :medium, validate: true

  validates :title, presence: { message: "を入力してください" }
  validates :priority, presence: true

  def self.human_attribute_name(attr, options = {})
    return "タスク名" if attr.to_s == "title"
    super
  end
end