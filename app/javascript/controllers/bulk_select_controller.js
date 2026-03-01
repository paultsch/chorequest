import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll", "bar", "count"]

  toggle() {
    const checked = this.checkboxTargets.filter(cb => cb.checked)
    if (this.hasCountTarget) {
      this.countTarget.textContent = `${checked.length} selected`
    }
    if (this.hasBarTarget) {
      this.barTarget.classList.toggle("hidden", checked.length === 0)
    }
    if (this.hasSelectAllTarget) {
      const total = this.checkboxTargets.length
      this.selectAllTarget.indeterminate = checked.length > 0 && checked.length < total
      this.selectAllTarget.checked = checked.length === total
    }
  }

  selectAll(event) {
    const checked = event.target.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.toggle()
  }
}
