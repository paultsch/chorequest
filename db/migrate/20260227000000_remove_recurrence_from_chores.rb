class RemoveRecurrenceFromChores < ActiveRecord::Migration[7.1]
  def change
    remove_column :chores, :recurrence, :string
  end
end
