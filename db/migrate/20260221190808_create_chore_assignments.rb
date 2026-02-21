class CreateChoreAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :chore_assignments do |t|
      t.references :child, null: false, foreign_key: true
      t.references :chore, null: false, foreign_key: true
      t.string :day
      t.boolean :completed
      t.boolean :approved
      t.string :completion_photo

      t.timestamps
    end
  end
end
