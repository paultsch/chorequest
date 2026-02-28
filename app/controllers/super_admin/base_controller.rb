module SuperAdmin
  class BaseController < ApplicationController
    before_action :authenticate_admin_user!
    layout 'application'

    helper_method :current_admin_user
  end
end
