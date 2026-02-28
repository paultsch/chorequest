class AdminAudit < ApplicationRecord
  belongs_to :admin, class_name: 'AdminUser', foreign_key: 'admin_id', optional: true

  def self.log!(admin:, action:, auditable: nil, metadata: {})
    create!(admin_id: admin&.id, action: action.to_s, auditable_type: auditable&.class&.name, auditable_id: auditable&.id, metadata: metadata)
  end
end
