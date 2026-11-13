class AddDetailsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :description, :text
    add_column :tasks, :priority, :integer
  end
end
