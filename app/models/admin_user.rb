class AdminUser < ApplicationRecord
  self.table_name = 'admins'

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  has_many :admin_audits, class_name: 'AdminAudit', foreign_key: 'admin_id', dependent: :nullify
end
