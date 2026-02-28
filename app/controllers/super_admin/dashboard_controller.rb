module SuperAdmin
  class DashboardController < SuperAdmin::BaseController
    def index
      @parents_count = Parent.count
      @active_parents_count = Parent.where(archived_at: nil).count
      @children_count = Child.count
      @chores_count = Chore.count
    end
  end
end
