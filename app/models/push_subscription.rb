class PushSubscription < ApplicationRecord
  belongs_to :parent, optional: true
  belongs_to :child,  optional: true

  validates :endpoint, :p256dh, :auth, presence: true
  validate  :belongs_to_someone

  private

  def belongs_to_someone
    errors.add(:base, "must belong to a parent or child") if parent_id.nil? && child_id.nil?
  end
end
