class ChoreAttempt < ApplicationRecord
  belongs_to :chore_assignment
  has_one_attached :photo

  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected' }, prefix: true

  delegate :child, :chore, to: :chore_assignment

  validates :photo, presence: true, if: -> { chore_assignment&.require_photo? }
end
