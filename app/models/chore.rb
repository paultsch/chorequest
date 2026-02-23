class Chore < ApplicationRecord
	has_many :chore_assignments, dependent: :destroy
end
