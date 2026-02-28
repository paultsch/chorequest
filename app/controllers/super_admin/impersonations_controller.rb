module SuperAdmin
  # Inherits ApplicationController directly (not BaseController) so this action
  # can run while the :admin_user scope is not active (we're signed in as a Parent).
  class ImpersonationsController < ApplicationController
    def destroy
      original_admin_id = session.delete(:original_admin_id)
      sign_out(:parent)

      if original_admin_id && (admin = AdminUser.find_by(id: original_admin_id))
        sign_in(:admin_user, admin)
        redirect_to super_admin_parents_path, notice: 'Impersonation ended.'
      else
        redirect_to new_admin_user_session_path, alert: 'Session expired. Please sign in again.'
      end
    end
  end
end
