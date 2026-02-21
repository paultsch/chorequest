class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :name
      t.text :description
      t.integer :token_per_minute

      t.timestamps
    end
  end
end
