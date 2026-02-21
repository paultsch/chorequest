json.extract! game_session, :id, :child_id, :game_id, :duration_minutes, :started_at, :ended_at, :created_at, :updated_at
json.url game_session_url(game_session, format: :json)
