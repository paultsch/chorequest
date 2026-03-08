import { Controller } from "@hotwired/stimulus"

// Manages the inline chore task list on the chore new/edit form.
// Handles adding new task rows, removing rows (marking _destroy),
// reordering via up/down buttons, and AI task suggestions via Rue.
export default class extends Controller {
  static targets = ["taskList", "template", "suggestButton", "suggestSpinner", "suggestLabel", "suggestError"]
  static values  = { suggestUrl: String }

  connect() {
    if (this.hasTaskListTarget) this.reindex()
  }

  addTask(event, titleValue = "") {
    event.preventDefault()
    if (!this.hasTaskListTarget) return
    const newIndex = this.taskList.children.length
    const html = this.templateTarget.innerHTML
      .replace(/__INDEX__/g, Date.now())
      .replace(/__POSITION__/g, newIndex)
    this.taskList.insertAdjacentHTML("beforeend", html)
    this.reindex()

    // If a title was provided (from suggestTasks), populate the input
    if (titleValue) {
      const rows = this.taskList.querySelectorAll(".chore-task-row:not([data-destroyed])")
      const last = rows[rows.length - 1]
      if (last) {
        const input = last.querySelector("input[type=text]")
        if (input) input.value = titleValue
      }
    } else {
      // Focus the new task title input
      const rows = this.taskList.querySelectorAll(".chore-task-row:not([data-destroyed])")
      const last = rows[rows.length - 1]
      if (last) last.querySelector("input[type=text]")?.focus()
    }
  }

  removeTask(event) {
    event.preventDefault()
    if (!this.hasTaskListTarget) return
    const row = event.target.closest(".chore-task-row")
    const destroyField = row.querySelector("input[name*='_destroy']")
    if (destroyField) {
      // Mark for destruction — hide the row
      destroyField.value = "1"
      row.classList.add("hidden")
      row.dataset.destroyed = "true"
    } else {
      // New row not yet persisted — just remove from DOM
      row.remove()
    }
    this.reindex()
  }

  moveUp(event) {
    event.preventDefault()
    const row = event.target.closest(".chore-task-row")
    const visibleRows = this.visibleRows()
    const idx = visibleRows.indexOf(row)
    if (idx <= 0) return
    const prev = visibleRows[idx - 1]
    this.taskList.insertBefore(row, prev)
    this.reindex()
  }

  moveDown(event) {
    event.preventDefault()
    const row = event.target.closest(".chore-task-row")
    const visibleRows = this.visibleRows()
    const idx = visibleRows.indexOf(row)
    if (idx < 0 || idx >= visibleRows.length - 1) return
    const next = visibleRows[idx + 1]
    this.taskList.insertBefore(next, row)
    this.reindex()
  }

  async suggestTasks(event) {
    event.preventDefault()

    const nameInput = document.getElementById("chore_name")
    const choreName = nameInput ? nameInput.value.trim() : ""

    if (!choreName) {
      this.showSuggestError("Please enter a chore name first.")
      return
    }

    this.setSuggestLoading(true)
    this.hideSuggestError()

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const response = await fetch(this.suggestUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ chore_name: choreName })
      })

      if (!response.ok) {
        const data = await response.json().catch(() => ({}))
        this.showSuggestError(data.error || "Something went wrong. Please try again.")
        return
      }

      const data = await response.json()
      const tasks = Array.isArray(data.tasks) ? data.tasks : []

      if (tasks.length === 0) {
        this.showSuggestError("No suggestions returned. Try a different chore name.")
        return
      }

      // Add each suggested task as a new row
      tasks.forEach(title => {
        const fakeEvent = { preventDefault: () => {} }
        this.addTask(fakeEvent, title)
      })

      // Open the details element if it isn't already
      const details = this.element.closest("details") || this.element
      if (details.tagName === "DETAILS") details.open = true

    } catch (err) {
      this.showSuggestError("Network error. Please try again.")
    } finally {
      this.setSuggestLoading(false)
    }
  }

  // Re-number position hidden inputs to reflect current DOM order.
  reindex() {
    this.visibleRows().forEach((row, i) => {
      const posField = row.querySelector("input[name*='[position]']")
      if (posField) posField.value = i
    })
  }

  visibleRows() {
    return Array.from(this.taskList.querySelectorAll(".chore-task-row")).filter(
      r => !r.dataset.destroyed && !r.classList.contains("hidden")
    )
  }

  setSuggestLoading(loading) {
    if (this.hasSuggestButtonTarget) this.suggestButtonTarget.disabled = loading
    if (this.hasSuggestSpinnerTarget) this.suggestSpinnerTarget.classList.toggle("hidden", !loading)
    if (this.hasSuggestLabelTarget)   this.suggestLabelTarget.textContent = loading ? "Thinking..." : "Suggest steps with Rue"
  }

  showSuggestError(message) {
    if (this.hasSuggestErrorTarget) {
      this.suggestErrorTarget.textContent = message
      this.suggestErrorTarget.classList.remove("hidden")
    }
  }

  hideSuggestError() {
    if (this.hasSuggestErrorTarget) {
      this.suggestErrorTarget.classList.add("hidden")
      this.suggestErrorTarget.textContent = ""
    }
  }

  get taskList() {
    return this.taskListTarget
  }
}
