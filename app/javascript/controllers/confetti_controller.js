import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._burst()
  }

  _burst() {
    const canvas = document.createElement("canvas")
    Object.assign(canvas.style, {
      position: "fixed",
      top: 0,
      left: 0,
      width: "100%",
      height: "100%",
      pointerEvents: "none",
      zIndex: 9999
    })
    canvas.width = window.innerWidth
    canvas.height = window.innerHeight
    document.body.appendChild(canvas)

    const ctx = canvas.getContext("2d")
    const colors = ["#f97316", "#3b82f6", "#10b981", "#a855f7", "#eab308", "#ec4899"]

    const pieces = Array.from({ length: 120 }, () => ({
      x: Math.random() * canvas.width,
      y: Math.random() * canvas.height - canvas.height,
      r: Math.random() * 6 + 4,
      d: Math.random() * 120 + 20,
      color: colors[Math.floor(Math.random() * colors.length)],
      tilt: 0,
      tiltAngle: 0,
      tiltSpeed: Math.random() * 0.1 + 0.05
    }))

    let angle = 0
    let tick = 0

    const draw = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height)
      angle += 0.01
      tick++

      pieces.forEach(p => {
        p.tiltAngle += p.tiltSpeed
        p.y += (Math.cos(angle + p.d) + 1 + p.r / 2) * 1.5
        p.tilt = Math.sin(p.tiltAngle) * 15

        ctx.beginPath()
        ctx.lineWidth = p.r / 2
        ctx.strokeStyle = p.color
        ctx.moveTo(p.x + p.tilt + p.r / 4, p.y)
        ctx.lineTo(p.x + p.tilt, p.y + p.tilt + p.r / 4)
        ctx.stroke()
      })

      if (tick < 200) {
        requestAnimationFrame(draw)
      } else {
        canvas.remove()
      }
    }

    draw()
  }
}
