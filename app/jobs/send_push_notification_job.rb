class SendPushNotificationJob < ApplicationJob
  queue_as :default

  def perform(subscription_id, title:, body:, url: "/")
    subscription = PushSubscription.find_by(id: subscription_id)
    return unless subscription

    case subscription.platform
    when "web"
      send_web_push(subscription, title: title, body: body, url: url)
    when "ios", "android"
      # Native push via Hotwire Native bridge — implemented when native wrappers are built
      Rails.logger.info "[PushNotification] Native push not yet implemented for platform: #{subscription.platform}"
    else
      Rails.logger.warn "[PushNotification] Unknown platform: #{subscription.platform}"
    end
  end

  private

  def send_web_push(subscription, title:, body:, url:)
    payload = JSON.generate({ title: title, body: body, url: url })

    Webpush.payload_send(
      message:   payload,
      endpoint:  subscription.endpoint,
      p256dh:    subscription.p256dh,
      auth:      subscription.auth,
      vapid: {
        subject:     VAPID_SUBJECT,
        public_key:  VAPID_PUBLIC_KEY,
        private_key: VAPID_PRIVATE_KEY
      }
    )
  rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
    Rails.logger.info "[PushNotification] Removing stale subscription #{subscription.id}: #{e.message}"
    subscription.destroy
  rescue => e
    Sentry.capture_exception(e, extra: { subscription_id: subscription.id })
    Rails.logger.error "[PushNotification] Failed to send to subscription #{subscription.id}: #{e.message}"
    # Do not re-raise — keep the queue healthy
  end
end
