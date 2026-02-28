class ChoreAssignment < ApplicationRecord
  belongs_to :child
  belongs_to :chore
  has_many :chore_attempts, dependent: :destroy

  serialize :extra_dates, coder: JSON

  validates :chore_id, :child_id, presence: true
  validates :scheduled_on, uniqueness: { scope: [:child_id, :chore_id], message: 'An assignment for this child, chore and date already exists' }, allow_nil: true

  def latest_attempt
    chore_attempts.order(:created_at).last
  end

  def pending_attempt?
    chore_attempts.where(status: 'pending').exists?
  end
end
