class CreateGameScores < ActiveRecord::Migration[7.0]
  def change
    create_table :game_scores do |t|
      t.references :child, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :score, null: false, default: 0

      t.timestamps
    end
    add_index :game_scores, [:game_id, :score]
  end
end
