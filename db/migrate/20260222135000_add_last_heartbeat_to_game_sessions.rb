class AddLastHeartbeatToGameSessions < ActiveRecord::Migration[7.0]
  def change
    add_column :game_sessions, :last_heartbeat, :datetime
    add_column :game_sessions, :stopped_early, :boolean, default: false, null: false
    add_index :game_sessions, :last_heartbeat
  end
end
