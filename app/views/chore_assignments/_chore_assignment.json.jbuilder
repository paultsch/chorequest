json.extract! chore_assignment, :id, :child_id, :chore_id, :day, :completed, :approved, :completion_photo, :created_at, :updated_at
json.url chore_assignment_url(chore_assignment, format: :json)
