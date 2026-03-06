class Billing::PortalController < ApplicationController
  before_action :authenticate_parent!

  def create
    unless current_parent.stripe_customer_id
      redirect_to root_path, alert: "No active subscription found."
      return
    end

    portal_session = Stripe::BillingPortal::Session.create(
      customer: current_parent.stripe_customer_id,
      return_url: root_url
    )

    redirect_to portal_session.url, allow_other_host: true
  end
end
