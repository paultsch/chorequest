import { Controller } from "@hotwired/stimulus"

// Handles push notification permission + subscription for parents and children.
//
// Usage:
//   data-controller="notifications"
//   data-notifications-subscribed-value="true|false"   (server-side hint: already subscribed?)
//
// Targets:
//   banner     — the whole opt-in card (hidden by default via CSS)
//   iosPrompt  — shown to iOS users who haven't installed the PWA yet
//   blockedMsg — shown when permission is denied
//   enableBtn  — the "Enable notifications" button
export default class extends Controller {
  static targets = ["banner", "iosPrompt", "blockedMsg", "enableBtn"]
  static values  = { subscribed: Boolean }

  connect() {
    // Don't show anything if the browser doesn't support push
    if (!("Notification" in window) || !("serviceWorker" in navigator)) return

    // Already granted and (presumably) subscribed — nothing to show
    if (Notification.permission === "granted" && this.subscribedValue) return

    // Permission explicitly denied — show the blocked message
    if (Notification.permission === "denied") {
      this.showBlockedMsg()
      return
    }

    // iOS Safari outside standalone mode — must install first
    if (this.isIos() && !this.isStandalone()) {
      this.showIosPrompt()
      return
    }

    // Show the opt-in banner
    this.showBanner()
  }

  async enable() {
    const permission = await Notification.requestPermission()

    if (permission !== "granted") {
      this.showBlockedMsg()
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const vapidKey = document.querySelector('meta[name="vapid-public-key"]')?.content

      if (!vapidKey) {
        console.error("[Notifications] VAPID public key meta tag missing")
        return
      }

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly:      true,
        applicationServerKey: this.urlBase64ToUint8Array(vapidKey)
      })

      const sub = subscription.toJSON()
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch("/push_subscriptions", {
        method:  "POST",
        headers: {
          "Content-Type":  "application/json",
          "X-CSRF-Token":  csrfToken
        },
        body: JSON.stringify({
          push_subscription: {
            endpoint:   sub.endpoint,
            p256dh:     sub.keys.p256dh,
            auth:       sub.keys.auth,
            platform:   "web",
            user_agent: navigator.userAgent.slice(0, 200)
          }
        })
      })

      if (response.ok) {
        this.hideBanner()
      } else {
        console.error("[Notifications] Failed to save subscription", await response.text())
      }
    } catch (err) {
      console.error("[Notifications] Subscription error:", err)
    }
  }

  dismiss() {
    localStorage.setItem("notifications-dismissed", Date.now())
    this.hideBanner()
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  showBanner() {
    // Don't re-show if dismissed within the last 30 days
    const dismissed = localStorage.getItem("notifications-dismissed")
    if (dismissed && Date.now() - parseInt(dismissed) < 30 * 24 * 60 * 60 * 1000) return

    if (this.hasBannerTarget) this.bannerTarget.classList.remove("hidden")
  }

  hideBanner() {
    if (this.hasBannerTarget) this.bannerTarget.classList.add("hidden")
  }

  showIosPrompt() {
    if (this.hasIosPromptTarget) this.iosPromptTarget.classList.remove("hidden")
  }

  showBlockedMsg() {
    if (this.hasBlockedMsgTarget) this.blockedMsgTarget.classList.remove("hidden")
    if (this.hasBannerTarget)     this.bannerTarget.classList.add("hidden")
  }

  isIos() {
    return /iphone|ipad|ipod/i.test(navigator.userAgent)
  }

  isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches ||
           window.navigator.standalone === true
  }

  // Converts a VAPID base64url public key to a Uint8Array for pushManager.subscribe()
  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64  = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const raw     = atob(base64)
    return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
  }
}
