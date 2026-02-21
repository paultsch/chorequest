class Child < ApplicationRecord
  belongs_to :parent

  has_many :chore_assignments, dependent: :destroy
  has_many :token_transactions, dependent: :destroy
  has_many :game_sessions, dependent: :destroy

  validates :name, presence: true

  def token_balance
    token_transactions.sum(:amount)
  end
end
