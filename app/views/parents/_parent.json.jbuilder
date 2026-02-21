json.extract! parent, :id, :name, :email, :password_digest, :is_admin, :created_at, :updated_at
json.url parent_url(parent, format: :json)
