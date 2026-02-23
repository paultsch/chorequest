import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    if (this.hasMenuTarget) {
      this.menuTargets.forEach(m => {
        m.classList.add('hidden')
        m.style.overflow = 'hidden'
        m.style.maxHeight = '0'
        m.style.transition = 'max-height 220ms ease'
      })
    }
  }

  toggle(event) {
    event.preventDefault()
    const btn = event.currentTarget || event.target
    const nav = btn.closest('nav') || this.element
    const menu = nav.querySelector('[data-nav-target="menu"]')
    if (!menu) return
    const isHidden = menu.classList.contains('hidden')

    if (isHidden) {
      menu.classList.remove('hidden')
      // ensure transition runs from 0
      menu.style.maxHeight = '0px'
      const height = menu.scrollHeight
      requestAnimationFrame(() => {
        menu.style.maxHeight = height + 'px'
      })
    } else {
      menu.style.maxHeight = '0px'
      const after = (e) => {
        if (e.propertyName === 'max-height') {
          menu.classList.add('hidden')
          menu.removeEventListener('transitionend', after)
        }
      }
      menu.addEventListener('transitionend', after)
    }

    const expanded = isHidden ? 'true' : 'false'
    if (btn && btn.getAttribute) btn.setAttribute('aria-expanded', expanded)
    else if (this.hasButtonTarget) this.buttonTarget.setAttribute('aria-expanded', expanded)

    // swap icons inside the clicked button if present
    try {
      const openIcon = btn.querySelector('.nav-open-icon')
      const closeIcon = btn.querySelector('.nav-close-icon')
      if (openIcon && closeIcon) {
        if (isHidden) {
          openIcon.classList.add('hidden')
          closeIcon.classList.remove('hidden')
        } else {
          openIcon.classList.remove('hidden')
          closeIcon.classList.add('hidden')
        }
      }
    } catch (err) {
      // ignore
    }
  }
}
