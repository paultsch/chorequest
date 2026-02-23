class AddScheduleFieldsToChoreAssignments < ActiveRecord::Migration[7.1]
  def change
    add_column :chore_assignments, :scheduled_on, :date
    add_column :chore_assignments, :recurrence, :string
    add_column :chore_assignments, :recurrence_end_on, :date
    add_column :chore_assignments, :extra_dates, :text
    add_index :chore_assignments, :scheduled_on
  end
end
