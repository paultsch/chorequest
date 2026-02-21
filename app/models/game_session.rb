class GameSession < ApplicationRecord
  belongs_to :child
  belongs_to :game
end
