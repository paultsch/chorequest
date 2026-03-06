class Billing::CheckoutController < ApplicationController
  before_action :authenticate_parent!

  def create
    price_id = Rails.application.credentials.dig(:stripe, :price_id)

    session = Stripe::Checkout::Session.create(
      customer_email: current_parent.email,
      mode: "subscription",
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: billing_success_url(session_id: "{CHECKOUT_SESSION_ID}"),
      cancel_url: billing_cancel_url,
      metadata: { parent_id: current_parent.id }
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    # Tier upgrade happens via webhook — just show confirmation here
  end

  def cancel
  end
end
