class SchoolMessage < ApplicationRecord
  belongs_to :parent

  CATEGORIES = %w[event homework permission_slip absence_alert newsletter announcement unknown].freeze

  scope :needs_attention, -> { where(needs_attention: true).order(created_at: :desc) }
  scope :actioned,        -> { where(actioned: true).order(created_at: :desc) }
  scope :recent,          -> { order(created_at: :desc) }
end
