import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choreName", "description", "definitionOfDone", "button", "status"]

  async improve() {
    const name        = this.choreNameTarget.value.trim()
    const description = this.descriptionTarget.value.trim()
    const current     = this.definitionOfDoneTarget.value.trim()

    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Improving..."
    this.statusTarget.textContent = ""

    try {
      const response = await fetch('/chores/improve_definition', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ name, description, definition_of_done: current })
      })

      const data = await response.json()

      if (!response.ok) {
        this.statusTarget.textContent = data.error || "Something went wrong."
        return
      }

      this.definitionOfDoneTarget.value = data.definition_of_done
    } catch (e) {
      this.statusTarget.textContent = "Request failed. Check your connection."
    } finally {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Improve with AI"
    }
  }
}
