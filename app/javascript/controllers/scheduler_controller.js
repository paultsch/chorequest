import { Controller } from "@hotwired/stimulus"

// Assignment Scheduler controller.
//
// Desktop: HTML5 drag-and-drop — drag a chore card, drop onto a calendar day.
// Mobile:  Tap-to-select — tap a chore to activate it (blue ring), then tap a
//          calendar day to assign it. Tap the same chore again to deselect.
//
// AJAX: POSTs to /chore_assignments (JSON) to create, DELETEs to remove.
// Chips are added/removed optimistically; the calendar frame is reloaded on failure.

export default class extends Controller {
  static targets = ["chore", "day", "chip", "chipContainer"]
  static values  = { childId: Number }

  connect() {
    this._draggingChore = null  // { id, name, tokens } set during desktop drag
    this._selectedChore = null  // { id, name, tokens } set by mobile tap
  }

  // ── Desktop: Drag & Drop ────────────────────────────────────────────────────

  dragStart(event) {
    this._draggingChore = this._choreDataFrom(event.currentTarget)
    event.dataTransfer.effectAllowed = "copy"
    // Brief visual cue that dragging has started
    event.currentTarget.classList.add("opacity-50")
    setTimeout(() => event.currentTarget.classList.remove("opacity-50"), 200)
  }

  dragOver(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
    event.currentTarget.classList.add("!bg-blue-100", "ring-2", "ring-blue-400", "ring-inset")
  }

  dragLeave(event) {
    event.currentTarget.classList.remove("!bg-blue-100", "ring-2", "ring-blue-400", "ring-inset")
  }

  drop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove("!bg-blue-100", "ring-2", "ring-blue-400", "ring-inset")
    if (!this._draggingChore) return

    const date    = event.currentTarget.dataset.date
    const childId = event.currentTarget.dataset.childId || this.childIdValue
    this._create(this._draggingChore, date, childId, event.currentTarget)
    this._draggingChore = null
  }

  // ── Mobile: Tap-to-select ───────────────────────────────────────────────────

  choreSelected(event) {
    // Prevent the touchend from also firing a click on the underlying day cell
    if (event.type === "touchend") event.preventDefault()

    const card  = event.currentTarget
    const chore = this._choreDataFrom(card)

    // Tapping the already-selected chore deselects it
    if (this._selectedChore?.id === chore.id) {
      this._selectedChore = null
      this._highlightChore(null)
      return
    }

    this._selectedChore = chore
    this._highlightChore(card)
  }

  dayClicked(event) {
    if (!this._selectedChore) return
    // Don't fire if the user clicked directly on an existing chip or its × button
    if (event.target.closest("[data-scheduler-target='chip']")) return

    const date    = event.currentTarget.dataset.date
    const childId = event.currentTarget.dataset.childId || this.childIdValue
    this._create(this._selectedChore, date, childId, event.currentTarget)
  }

  // ── Remove ──────────────────────────────────────────────────────────────────

  async removeAssignment(event) {
    event.stopPropagation()
    const assignmentId = event.currentTarget.dataset.assignmentId
    const chip = event.currentTarget.closest("[data-scheduler-target='chip']")

    // Optimistic removal
    chip?.remove()

    try {
      const resp = await fetch(`/chore_assignments/${assignmentId}`, {
        method:  "DELETE",
        headers: {
          "X-CSRF-Token": this._csrf(),
          "Accept":       "application/json"
        }
      })
      if (!resp.ok) throw new Error("Delete failed")
    } catch {
      // Restore state on failure
      this._reloadCalendarFrame()
    }
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  async _create(chore, date, childId, dayCell) {
    if (!childId || childId === "0") return

    // Guard: don't create a duplicate chip for the same chore on the same day
    const container = dayCell.querySelector("[data-scheduler-target='chipContainer']")
    if (!container) return

    const alreadyAssigned = [...container.querySelectorAll("[data-scheduler-target='chip']")]
      .some(c => c.dataset.choreId == chore.id)
    if (alreadyAssigned) return

    // Optimistic: render a temporary chip immediately
    const tempChip = this._buildChip({ id: "temp", chore_name: chore.name, chore_id: chore.id })
    container.appendChild(tempChip)

    try {
      const resp = await fetch("/chore_assignments", {
        method:  "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this._csrf(),
          "Accept":       "application/json"
        },
        body: JSON.stringify({
          chore_assignment: {
            chore_id:     chore.id,
            child_id:     childId,
            scheduled_on: date
          }
        })
      })

      if (resp.status === 422) {
        // Duplicate — the DB unique index caught it; silently remove temp chip
        tempChip.remove()
        return
      }

      if (!resp.ok) throw new Error("Create failed")

      const data = await resp.json()
      // Update temp chip with the real assignment id so × deletion works
      tempChip.dataset.assignmentId = data.id
      const removeBtn = tempChip.querySelector("[data-action*='removeAssignment']")
      if (removeBtn) removeBtn.dataset.assignmentId = data.id

    } catch {
      tempChip.remove()
    }
  }

  // Build a chip DOM node that mirrors _chore_chip.html.erb
  _buildChip({ id, chore_name, chore_id }) {
    const div = document.createElement("div")
    div.className = "chore-chip group flex items-center justify-between gap-1 bg-blue-100 text-blue-800 rounded px-1.5 py-0.5 text-xs font-medium max-w-full"
    div.dataset.schedulerTarget = "chip"
    div.dataset.assignmentId    = id
    div.dataset.choreId         = chore_id
    div.innerHTML = `
      <span class="truncate leading-tight">${this._escape(chore_name)}</span>
      <button type="button"
              class="flex-shrink-0 ml-0.5 text-blue-400 hover:text-red-500 transition-colors leading-none opacity-100 md:opacity-0 md:group-hover:opacity-100"
              aria-label="Remove assignment"
              data-action="click->scheduler#removeAssignment"
              data-assignment-id="${id}">×</button>`
    return div
  }

  _choreDataFrom(card) {
    return {
      id:     card.dataset.choreId,
      name:   card.dataset.choreName,
      tokens: card.dataset.choreTokens
    }
  }

  _highlightChore(activeCard) {
    this.choreTargets.forEach(c =>
      c.classList.remove("border-blue-500", "ring-2", "ring-blue-400", "shadow-md")
    )
    if (activeCard) {
      activeCard.classList.add("border-blue-500", "ring-2", "ring-blue-400", "shadow-md")
    }
  }

  _csrf() {
    return document.querySelector("meta[name='csrf-token']")?.content ?? ""
  }

  _reloadCalendarFrame() {
    const frame = document.querySelector("turbo-frame#scheduler-calendar")
    frame?.reload()
  }

  // Prevent XSS in dynamically built chip names
  _escape(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
