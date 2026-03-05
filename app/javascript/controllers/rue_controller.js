import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "messages", "input", "sendButton"]

  connect() {
    this._loading = false
    this._greeted = false
    this._keyHandler = (e) => {
      if (e.key === "Escape" && !this.panelTarget.classList.contains("hidden")) {
        this.close()
      }
    }
    document.addEventListener("keydown", this._keyHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this._keyHandler)
  }

  toggle() {
    if (this.panelTarget.classList.contains("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    this.inputTarget.focus()

    // Show a greeting the first time the panel opens (client-side only, no API call)
    if (!this._greeted) {
      this._greeted = true
      this._appendMessage(
        "Hi! I'm Rue, your ChoreQuest assistant. I can help you manage your family — try saying \"add a new child\"!",
        "rue"
      )
    }
  }

  close() {
    this.panelTarget.classList.add("hidden")
  }

  async send(event) {
    event.preventDefault()
    const message = this.inputTarget.value.trim()
    if (!message || this._loading) return

    this._appendMessage(message, "user")
    this.inputTarget.value = ""
    this._setLoading(true)

    try {
      const response = await fetch("/rue/chat", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ message })
      })

      if (!response.ok) throw new Error("Request failed")
      const data = await response.json()
      this._appendMessage(data.reply, "rue")
    } catch (_e) {
      this._appendMessage("Sorry, something went wrong. Please try again.", "error")
    } finally {
      this._setLoading(false)
      this.inputTarget.focus()
    }
  }

  // Allow sending with Enter key (Shift+Enter inserts newline if input were a textarea)
  handleEnter(event) {
    if (event.key === "Enter") {
      event.preventDefault()
      this.send(event)
    }
  }

  _appendMessage(text, type) {
    const wrapper = document.createElement("div")
    wrapper.className = type === "user" ? "flex justify-end mb-3" : "flex justify-start mb-3"

    const bubble = document.createElement("div")
    bubble.className = type === "user"
      ? "bg-indigo-600 text-white rounded-2xl rounded-br-sm px-3 py-2 max-w-[85%] text-sm leading-relaxed"
      : "bg-gray-100 text-gray-800 rounded-2xl rounded-bl-sm px-3 py-2 max-w-[85%] text-sm leading-relaxed"
    bubble.textContent = text

    wrapper.appendChild(bubble)
    this.messagesTarget.appendChild(wrapper)
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  _setLoading(loading) {
    this._loading = loading
    this.sendButtonTarget.disabled = loading
    this.inputTarget.disabled = loading

    const typingId = "rue-typing-indicator"
    if (loading) {
      const wrapper = document.createElement("div")
      wrapper.id = typingId
      wrapper.className = "flex justify-start mb-3"
      wrapper.innerHTML = `<div class="bg-gray-100 text-gray-400 rounded-2xl rounded-bl-sm px-3 py-2 text-sm italic">Rue is thinking...</div>`
      this.messagesTarget.appendChild(wrapper)
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    } else {
      document.getElementById(typingId)?.remove()
    }
  }
}
