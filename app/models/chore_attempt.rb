class ChoreAttempt < ApplicationRecord
  belongs_to :chore_assignment
  belongs_to :chore_task, optional: true
  has_one_attached :photo

  enum :status, { pending: 'pending', approved: 'approved', rejected: 'rejected' }, prefix: true

  delegate :child, :chore, to: :chore_assignment

  validates :photo, presence: true, if: -> { chore_assignment&.require_photo? || chore_task&.photo_required? }

  after_create :notify_parent_of_submission
  after_update :notify_child_of_verdict, if: :saved_change_to_status?

  private

  def notify_parent_of_submission
    NotificationService.notify_parent_of_submission(self)
  end

  def notify_child_of_verdict
    if status_approved?
      NotificationService.notify_child_of_approval(self)
    elsif status_rejected?
      NotificationService.notify_child_of_rejection(self)
    end
  end
end
