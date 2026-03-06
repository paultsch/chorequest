class PushSubscriptionsController < ApplicationController
  # The subscription POST comes from a Stimulus fetch() call (same-origin, includes CSRF token
  # via meta tag). No need to skip CSRF here.

  def create
    attrs = subscription_params.merge(owner_attrs)

    if attrs[:parent_id].nil? && attrs[:child_id].nil?
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # Upsert by endpoint — same device re-subscribing updates keys rather than creating a duplicate
    subscription = PushSubscription.find_or_initialize_by(endpoint: attrs[:endpoint])
    subscription.assign_attributes(attrs)

    if subscription.save
      render json: { id: subscription.id }, status: :created
    else
      render json: { errors: subscription.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    subscription = PushSubscription.find_by(id: params[:id])

    if subscription && authorized_subscription?(subscription)
      subscription.destroy
      head :no_content
    else
      head :not_found
    end
  end

  private

  def subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh, :auth, :platform, :user_agent)
  end

  def owner_attrs
    if parent_signed_in?
      { parent_id: current_parent.id, child_id: nil }
    elsif session[:child_id].present?
      { child_id: session[:child_id], parent_id: nil }
    else
      {}
    end
  end

  def authorized_subscription?(subscription)
    (parent_signed_in? && subscription.parent_id == current_parent.id) ||
      (session[:child_id].present? && subscription.child_id == session[:child_id])
  end
end
