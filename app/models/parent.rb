class Parent < ApplicationRecord
	# Devise modules. Others available are:
	# :confirmable, :lockable, :timeoutable, :trackable, :omniauthable
	devise :database_authenticatable, :registerable,
				 :recoverable, :rememberable, :validatable

	has_many :children, dependent: :destroy
	has_many :chores, dependent: :destroy

	validates :name, presence: true
end
