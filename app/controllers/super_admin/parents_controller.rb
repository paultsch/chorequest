module SuperAdmin
  class ParentsController < SuperAdmin::BaseController
    before_action :set_parent, only: [:show, :edit, :update, :impersonate, :reactivate]

    def index
      @parents = Parent.order(:id).page(params[:page]).per(30)
    end

    def show
    end

    def edit
    end

    def update
      if @parent.update(parent_params)
        AdminAudit.log!(admin: current_admin_user, action: 'update_parent', auditable: @parent)
        redirect_to super_admin_parent_path(@parent), notice: 'Parent updated'
      else
        render :edit
      end
    end

    def impersonate
      AdminAudit.log!(admin: current_admin_user, action: 'impersonate_parent', auditable: @parent)
      session[:original_admin_id] = current_admin_user.id
      sign_in(:parent, @parent)
      redirect_to root_path, notice: "Now impersonating #{@parent.name || @parent.email}"
    end

    def reactivate
      @parent.update(archived_at: nil)
      AdminAudit.log!(admin: current_admin_user, action: 'reactivate_parent', auditable: @parent)
      redirect_to super_admin_parent_path(@parent), notice: 'Parent reactivated'
    end

    private

    def set_parent
      @parent = Parent.find(params[:id])
    end

    def parent_params
      params.require(:parent).permit(:name, :email)
    end
  end
end
