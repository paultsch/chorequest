class Chore < ApplicationRecord
  belongs_to :parent
  has_many :chore_assignments, dependent: :destroy
  has_many :chore_tasks, -> { order(:position) }, dependent: :destroy

  has_one_attached :model_photo

  accepts_nested_attributes_for :chore_tasks,
    allow_destroy: true,
    reject_if: :all_blank

  validates :name, presence: true
end
