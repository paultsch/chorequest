class CreateChoreTasks < ActiveRecord::Migration[7.1]
  def change
    create_table :chore_tasks do |t|
      t.references :chore, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :position, null: false, default: 0
      t.boolean :photo_required, null: false, default: false

      t.timestamps
    end

    add_index :chore_tasks, [:chore_id, :position]
  end
end
