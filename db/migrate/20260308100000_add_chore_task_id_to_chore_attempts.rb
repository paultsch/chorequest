class AddChoreTaskIdToChoreAttempts < ActiveRecord::Migration[7.1]
  def change
    add_reference :chore_attempts, :chore_task, null: true, foreign_key: true, index: true
  end
end
