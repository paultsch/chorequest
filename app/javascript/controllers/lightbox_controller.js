import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "image"]

  connect() {
    this._keyHandler = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this._keyHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this._keyHandler)
  }

  open(event) {
    const src = event.params.src
    if (!src) return
    this.imageTarget.src = src
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.imageTarget.src = ""
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop(event) {
    if (event.target === this.overlayTarget) this.close()
  }
}
