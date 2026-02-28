class Chore < ApplicationRecord
  belongs_to :parent
  has_many :chore_assignments, dependent: :destroy

  validates :name, presence: true
end
