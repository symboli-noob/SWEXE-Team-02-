class AddScheduleAndStatusToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :scheduled_at, :datetime
    add_column :tasks, :status, :integer, null: false, default: 0
    add_index :tasks, :scheduled_at
  end
end
