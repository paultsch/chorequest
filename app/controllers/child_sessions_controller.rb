class ChildSessionsController < ApplicationController
  def new
  end

  def create
    child = Child.find_by(id: params[:child_id])
    if child && params[:pin_code].present? && child.pin_code == params[:pin_code]
      session[:child_id] = child.id
      redirect_to child_path(child), notice: "Signed in as #{child.name}"
    else
      flash.now[:alert] = 'Invalid child or PIN'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:child_id)
    redirect_to root_path, notice: 'Signed out'
  end
end
