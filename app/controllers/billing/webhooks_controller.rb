class Billing::WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError
      return head :bad_request
    rescue Stripe::SignatureVerificationError
      return head :bad_request
    end

    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    parent = Parent.find_by(id: session.metadata["parent_id"])
    return unless parent

    parent.update!(
      stripe_customer_id: session.customer,
      stripe_subscription_id: session.subscription,
      plan_tier: "paid",
      subscription_status: "active"
    )
  end

  def handle_subscription_updated(subscription)
    parent = Parent.find_by(stripe_subscription_id: subscription.id)
    return unless parent

    parent.update!(subscription_status: subscription.status)
  end

  def handle_subscription_deleted(subscription)
    parent = Parent.find_by(stripe_subscription_id: subscription.id)
    return unless parent

    parent.update!(
      plan_tier: "free",
      subscription_status: "canceled",
      stripe_subscription_id: nil
    )
  end

  def handle_payment_failed(invoice)
    parent = Parent.find_by(stripe_customer_id: invoice.customer)
    return unless parent

    parent.update!(subscription_status: "past_due")
  end
end
