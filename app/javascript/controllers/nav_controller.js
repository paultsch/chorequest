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
    const btn = event.currentTarget || event.target
    const nav = btn.closest('nav') || this.element
    const menu = nav.querySelector('[data-nav-target="menu"]')
    if (!menu) return
    menu.classList.toggle('hidden')
    const expanded = menu.classList.contains('hidden') ? 'false' : 'true'
    if (btn && btn.getAttribute) btn.setAttribute('aria-expanded', expanded)
    else if (this.hasButtonTarget) this.buttonTarget.setAttribute('aria-expanded', expanded)
  }
}
