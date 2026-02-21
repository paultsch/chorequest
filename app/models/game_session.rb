class GameSession < ApplicationRecord
  belongs_to :child
  belongs_to :game

  validates :duration_minutes, numericality: { greater_than: 0 }

  before_create :set_started_and_ended_times

  private

  def set_started_and_ended_times
    self.started_at ||= Time.current
    self.ended_at ||= started_at + duration_minutes.minutes
  end
end
