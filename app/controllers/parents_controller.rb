class ParentsController < ApplicationController
  before_action :authenticate_parent!
  before_action :set_parent, only: %i[ show edit update destroy ]

  # GET /parents/1/edit (Settings)
  def edit
  end

  # PATCH/PUT /parents/1
  def update
    # If password change is requested, verify the current password first
    if parent_params[:password].present?
      unless @parent.valid_password?(params[:parent][:current_password])
        @parent.errors.add(:base, "Current password is incorrect")
        render :edit, status: :unprocessable_entity and return
      end
    end

    # Strip blank password fields so a profile-only update doesn't touch the password
    safe_params = parent_params
    if safe_params[:password].blank?
      safe_params = safe_params.except(:password, :password_confirmation)
    end

    if @parent.update(safe_params)
      # Keep the session alive if password or email changed
      bypass_sign_in(@parent) if safe_params[:password].present?
      redirect_to edit_parent_path(@parent), notice: "Settings updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /parents/1
  def destroy
    sign_out(current_parent)
    @parent.destroy!
    redirect_to root_path, notice: "Your account has been deleted."
  end

  private

  def set_parent
    # Parents can only manage their own account
    @parent = current_parent
    unless @parent.id == params[:id].to_i
      redirect_to edit_parent_path(current_parent), alert: "Not authorized." and return
    end
  end

  def parent_params
    params.require(:parent).permit(:name, :email, :password, :password_confirmation)
  end
end
