class Child < ApplicationRecord
  belongs_to :parent

  has_many :chore_assignments, dependent: :destroy
  has_many :token_transactions, dependent: :destroy
  has_many :game_sessions, dependent: :destroy

  validates :name, presence: true

  def token_balance
    token_transactions.sum(:amount)
  end

  # Generate a URL-safe public token for this child and persist it.
  def generate_public_token!(length: 24)
    self.public_token = SecureRandom.urlsafe_base64(length)
    save!
    public_token
  end

  def public_link(host: nil)
    return unless public_token
    Rails.application.routes.url_helpers.public_child_path(public_token)
  end
end
