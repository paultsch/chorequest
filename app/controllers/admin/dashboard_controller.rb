module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_parent!

    def index
      child_ids = current_parent.children.select(:id)
      @children = current_parent.children.includes(:chore_assignments)
      @pending_attempts = ChoreAttempt.includes(chore_assignment: [:child, :chore, :chore_attempts])
                                       .where(chore_assignments: { child_id: child_ids }, status: 'pending')
                                       .order(created_at: :desc)
    end
  end
end
