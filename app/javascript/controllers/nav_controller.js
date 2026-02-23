import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    if (this.hasMenuTarget) {
      this.menuTarget.classList.add('hidden')
    }
  }

  toggle(event) {
    event.preventDefault()
    if (!this.hasMenuTarget || !this.hasButtonTarget) return
    this.menuTarget.classList.toggle('hidden')
    const expanded = this.menuTarget.classList.contains('hidden') ? 'false' : 'true'
    this.buttonTarget.setAttribute('aria-expanded', expanded)
  }
}
