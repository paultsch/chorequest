json.extract! game, :id, :name, :description, :token_per_minute, :created_at, :updated_at
json.url game_url(game, format: :json)
