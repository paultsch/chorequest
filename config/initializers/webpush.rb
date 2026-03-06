VAPID_PUBLIC_KEY  = ENV.fetch("VAPID_PUBLIC_KEY",  Rails.application.credentials.dig(:vapid, :public_key))
VAPID_PRIVATE_KEY = ENV.fetch("VAPID_PRIVATE_KEY", Rails.application.credentials.dig(:vapid, :private_key))
VAPID_SUBJECT     = ENV.fetch("VAPID_SUBJECT",     "mailto:admin@pyrch.ai")
