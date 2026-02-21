class CreateGameSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :game_sessions do |t|
      t.references :child, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.integer :duration_minutes
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
