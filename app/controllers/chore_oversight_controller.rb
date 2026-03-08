class ChoreOversightController < ApplicationController
  before_action :authenticate_parent!

  def index
    chores = current_parent.chores.includes(:chore_assignments => :chore_attempts)

    today = Date.today

    @rows = chores.map do |chore|
      # Find most recent approved attempt across all assignments for this chore
      last_approved_assignment = chore.chore_assignments
        .select { |a| a.approved == true && a.completed_at.present? }
        .max_by(&:completed_at)

      last_completed_on = last_approved_assignment&.completed_at&.to_date

      frequency_days = chore.frequency_days

      due_on = if last_completed_on && frequency_days
        last_completed_on + frequency_days
      end

      days_until_due = due_on ? (due_on - today).to_i : nil

      status = if frequency_days.nil?
        :no_schedule
      elsif days_until_due.nil?
        # Has frequency but never completed — treat as overdue since day 0
        :overdue
      elsif days_until_due < 0
        :overdue
      elsif days_until_due <= 2
        :due_soon
      else
        :ok
      end

      {
        chore:             chore,
        last_completed_on: last_completed_on,
        frequency_days:    frequency_days,
        due_on:            due_on,
        days_until_due:    days_until_due,
        status:            status
      }
    end

    # Sort: overdue first, due_soon, ok, no_schedule
    status_order = { overdue: 0, due_soon: 1, ok: 2, no_schedule: 3 }
    @rows.sort_by! { |r| [status_order[r[:status]], r[:days_until_due] || 9999] }
  end
end
