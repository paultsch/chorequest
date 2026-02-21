class ChoreAssignment < ApplicationRecord
  belongs_to :child
  belongs_to :chore

  validates :day, presence: true

  # When a parent approves a completed chore, grant tokens to the child
  after_update :grant_tokens_after_approval, if: :saved_change_to_approved?

  private

  def grant_tokens_after_approval
    return unless approved && completed

    TokenTransaction.create!(child: child, amount: chore.token_amount || 0, description: "Chore approved: #{chore.name}")
  end
end
