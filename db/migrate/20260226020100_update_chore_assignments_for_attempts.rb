class UpdateChoreAssignmentsForAttempts < ActiveRecord::Migration[7.1]
  def change
    add_column :chore_assignments, :require_photo, :boolean, default: false, null: false
    remove_column :chore_assignments, :completion_photo, :string
  end
end
