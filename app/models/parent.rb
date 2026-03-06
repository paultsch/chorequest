class Parent < ApplicationRecord
	# Devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
	devise :database_authenticatable, :registerable,
				 :recoverable, :rememberable, :validatable

	has_many :children, dependent: :destroy
	has_many :chores, dependent: :destroy
	has_many :school_messages, dependent: :destroy
	has_many :push_subscriptions, dependent: :destroy

	validates :name, presence: true

  def paid?
    plan_tier == "paid"
  end

  def free?
    plan_tier == "free"
  end

  def subscription_active?
    paid? && subscription_status == "active"
  end
end
