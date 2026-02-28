import { Controller } from "@hotwired/stimulus"

// Handles the PWA install prompt (Chrome/Edge/Android only).
// Safari/iOS users must use "Add to Home Screen" from the share sheet manually —
// the beforeinstallprompt event is not available there, so the banner simply
// never appears on iOS, which is correct behavior.
export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this._deferredPrompt = null

    // Don't show the banner if already running in standalone (installed) mode
    if (window.matchMedia("(display-mode: standalone)").matches) return

    // Don't show if the user dismissed it within the last 7 days
    const dismissed = localStorage.getItem("pwa-install-dismissed")
    if (dismissed && Date.now() - parseInt(dismissed) < 7 * 24 * 60 * 60 * 1000) return

    window.addEventListener("beforeinstallprompt", (event) => {
      event.preventDefault()
      this._deferredPrompt = event
      this.showBanner()
    })
  }

  showBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.remove("hidden")
    }
  }

  hideBanner() {
    if (this.hasBannerTarget) {
      this.bannerTarget.classList.add("hidden")
    }
  }

  async install() {
    if (!this._deferredPrompt) return

    this._deferredPrompt.prompt()
    await this._deferredPrompt.userChoice

    this._deferredPrompt = null
    this.hideBanner()
  }

  dismiss() {
    localStorage.setItem("pwa-install-dismissed", Date.now())
    this.hideBanner()
  }
}
