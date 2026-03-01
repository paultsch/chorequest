module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_parent!

    def index
      today = Date.current
      child_ids = current_parent.children.select(:id)

      @children = current_parent.children
        .includes(:chore_assignments, :token_transactions)
        .order(:name)

      @pending_attempts = ChoreAttempt
        .includes(chore_assignment: [:child, :chore, :chore_attempts])
        .where(chore_assignments: { child_id: child_ids }, status: 'pending')
        .order(created_at: :desc)

      # Today's assignments grouped by child for the "Today at a Glance" panel
      todays_assignments = ChoreAssignment
        .includes(:chore, :chore_attempts)
        .where(child_id: child_ids, scheduled_on: today)
      @todays_by_child = todays_assignments.group_by(&:child_id)

      # Overdue: past due, not approved, not currently pending a re-attempt (cap at 10)
      overdue = ChoreAssignment
        .includes(:chore)
        .joins(:child)
        .where(children: { parent_id: current_parent.id })
        .where('scheduled_on < ?', today)
        .where(approved: [false, nil])
        .where(completed: [false, nil])
        .order(:scheduled_on)
        .limit(10)
      @overdue_by_child = overdue.group_by(&:child_id)

      # Last 20 approved chore attempts for the completed feed
      @approved_attempts = ChoreAttempt
        .includes(chore_assignment: [:child, :chore])
        .joins(chore_assignment: :child)
        .where(children: { parent_id: current_parent.id }, status: 'approved')
        .order(updated_at: :desc)
        .limit(20)
    end
  end
end
