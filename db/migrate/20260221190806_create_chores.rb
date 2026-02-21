class CreateChores < ActiveRecord::Migration[7.1]
  def change
    create_table :chores do |t|
      t.string :name
      t.text :description
      t.text :definition_of_done
      t.integer :token_amount
      t.string :recurrence

      t.timestamps
    end
  end
end
