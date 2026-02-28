class ApplicationController < ActionController::Base
	before_action :configure_permitted_parameters, if: :devise_controller?

	protected

	def configure_permitted_parameters
		added_attrs = [:name, :display_name, :phone, :accepted_terms]
		devise_parameter_sanitizer.permit(:sign_up, keys: added_attrs)
		devise_parameter_sanitizer.permit(:account_update, keys: added_attrs)
	end

	def after_sign_up_path_for(resource)
		root_path
	end

	def after_sign_in_path_for(resource)
		if resource.is_a?(AdminUser)
			# send admin users to the super-admin dashboard
			super_admin_root_path
		else
			super
		end
	end
end
