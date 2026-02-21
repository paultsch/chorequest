json.extract! child, :id, :name, :age, :parent_id, :pin_code, :created_at, :updated_at
json.url child_url(child, format: :json)
