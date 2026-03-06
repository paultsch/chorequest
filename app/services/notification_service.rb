class NotificationService
  def self.notify_parent_of_submission(chore_attempt)
    child = chore_attempt.child
    chore = chore_attempt.chore
    parent_id = child.parent_id

    subscriptions = PushSubscription.where(parent_id: parent_id)
    return if subscriptions.empty?

    title = "#{child.name} submitted a chore"
    body  = "'#{chore.name}' is ready for your review"
    url   = "/admin"

    subscriptions.each do |sub|
      SendPushNotificationJob.perform_later(sub.id, title: title, body: body, url: url)
    end
  end

  def self.notify_child_of_approval(chore_attempt)
    child  = chore_attempt.child
    chore  = chore_attempt.chore
    tokens = chore.token_amount.to_i

    subscriptions = PushSubscription.where(child_id: child.id)
    return if subscriptions.empty?

    title = "#{chore.name} approved!"
    body  = tokens > 0 ? "You earned #{tokens} token#{tokens == 1 ? '' : 's'}!" : "Great job!"
    url   = "/public/#{child.public_token}"

    subscriptions.each do |sub|
      SendPushNotificationJob.perform_later(sub.id, title: title, body: body, url: url)
    end
  end

  def self.notify_child_of_rejection(chore_attempt)
    child = chore_attempt.child
    chore = chore_attempt.chore

    subscriptions = PushSubscription.where(child_id: child.id)
    return if subscriptions.empty?

    title = "#{chore.name} needs another try"
    body  = "Your grownup left a note — check it out!"
    url   = "/public/#{child.public_token}"

    subscriptions.each do |sub|
      SendPushNotificationJob.perform_later(sub.id, title: title, body: body, url: url)
    end
  end
end
