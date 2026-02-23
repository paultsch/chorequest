class ChoreAssignment < ApplicationRecord
  belongs_to :child
  belongs_to :chore

  serialize :extra_dates, coder: JSON

  validates :chore_id, :child_id, presence: true
  validates :scheduled_on, uniqueness: { scope: [:child_id, :chore_id], message: 'An assignment for this child, chore and date already exists' }, allow_nil: true

  # When a parent approves a completed chore, grant tokens to the child
  after_update :grant_tokens_after_approval, if: :saved_change_to_approved?

  private

  def grant_tokens_after_approval
    return unless approved && completed

    TokenTransaction.create!(child: child, amount: chore.token_amount || 0, description: "Chore approved: #{chore.name}")
  end
end
