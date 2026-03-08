class ChoreTask < ApplicationRecord
  belongs_to :chore
  has_many :chore_attempts

  has_one_attached :model_photo

  validates :title, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
