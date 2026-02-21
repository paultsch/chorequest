class TokenTransaction < ApplicationRecord
  belongs_to :child

  validates :amount, presence: true
  validates :description, presence: true
end
