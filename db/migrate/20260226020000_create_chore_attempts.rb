class CreateChoreAttempts < ActiveRecord::Migration[7.1]
  def change
    create_table :chore_attempts do |t|
      t.references :chore_assignment, null: false, foreign_key: true
      t.string :status, null: false, default: 'pending'
      t.text :parent_note

      t.timestamps
    end

    add_index :chore_attempts, [:chore_assignment_id, :status]
  end
end
