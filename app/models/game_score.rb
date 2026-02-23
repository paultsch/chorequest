class GameScore < ApplicationRecord
  belongs_to :child
  belongs_to :game

  validates :score, presence: true
end
