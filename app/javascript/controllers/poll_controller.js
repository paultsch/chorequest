import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 30 } }

  connect() {
    this._url = window.location.href
    this.timer = setInterval(() => {
      const frame = this.element.querySelector("turbo-frame")
      if (frame) frame.src = this._url
    }, this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
