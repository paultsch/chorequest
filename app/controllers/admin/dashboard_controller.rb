module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_parent!
    before_action :require_admin

    def index
      @children = Child.includes(:chore_assignments).all
      @chore_assignments_today = ChoreAssignment.where(day: Date.today.strftime('%A'))
    end

    private

    def require_admin
      redirect_to root_path, alert: 'Admins only' unless current_parent.is_admin?
    end
  end
end
