module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_parent!

    def index
      child_ids = current_parent.children.select(:id)
      @children = current_parent.children.includes(:chore_assignments)
      @pending_approvals = ChoreAssignment.includes(:child, :chore).where(child_id: child_ids, completed: true, approved: false).order(created_at: :desc)
      @chore_assignments_today = ChoreAssignment.where(child_id: child_ids, day: Date.today.strftime('%A'))
    end
  end
end
