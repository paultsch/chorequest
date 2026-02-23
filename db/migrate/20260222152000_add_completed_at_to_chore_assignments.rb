class AddCompletedAtToChoreAssignments < ActiveRecord::Migration[7.0]
  def change
    add_column :chore_assignments, :completed_at, :datetime
    add_index :chore_assignments, :completed_at
  end
end
