json.extract! token_transaction, :id, :child_id, :amount, :description, :created_at, :updated_at
json.url token_transaction_url(token_transaction, format: :json)
