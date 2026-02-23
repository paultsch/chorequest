import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    if (this.hasMenuTarget) {
      this.menuTargets.forEach(m => m.classList.add('hidden'))
    }
  }

  toggle(event) {
    event.preventDefault()
    if (!this.hasMenuTarget || !this.hasButtonTarget) return
    this.menuTargets.forEach(m => m.classList.toggle('hidden'))
    const expanded = this.menuTargets[0].classList.contains('hidden') ? 'false' : 'true'
    this.buttonTarget.setAttribute('aria-expanded', expanded)
  }
}
