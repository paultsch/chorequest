class CreateChildren < ActiveRecord::Migration[7.1]
  def change
    create_table :children do |t|
      t.string :name
      t.integer :age
      t.references :parent, null: false, foreign_key: true
      t.string :pin_code

      t.timestamps
    end
  end
end
