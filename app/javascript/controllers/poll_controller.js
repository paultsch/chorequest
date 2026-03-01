import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 30 } }

  connect() {
    this.timer = setInterval(() => {
      const frame = this.element.querySelector("turbo-frame")
      frame?.reload()
    }, this.intervalValue * 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
