import { Controller } from "@hotwired/stimulus"

// Assignment Scheduler controller.
//
// Desktop: HTML5 drag-and-drop — drag a chore card, drop onto a calendar day.
// Mobile:  Tap-to-select — tap a chore to activate it (blue ring), then tap a
//          calendar day to assign it. Tap the same chore again to deselect.
//
// AJAX: POSTs to /chore_assignments (JSON) to create, DELETEs to remove,
//       PATCHes to /chore_assignments/:id to toggle require_photo.
// Chips are added/removed optimistically; the calendar frame is reloaded on failure.

export default class extends Controller {
  static targets = ["chore", "day", "chip", "chipContainer"]
  static values  = { childId: Number }

  connect() {
    this._draggingChore = null  // { id, name, tokens, requirePhoto } set during desktop drag
    this._selectedChore = null  // { id, name, tokens, requirePhoto } set by mobile tap
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
    // Don't fire if the user clicked directly on an existing chip or its buttons
    if (event.target.closest("[data-scheduler-target='chip']")) return

    const date    = event.currentTarget.dataset.date
    const childId = event.currentTarget.dataset.childId || this.childIdValue
    this._create(this._selectedChore, date, childId, event.currentTarget)
  }

  // ── Photo toggle on chore card (client-side only) ───────────────────────────

  toggleChorePhoto(event) {
    event.stopPropagation()
    const btn  = event.currentTarget
    const card = btn.closest("[data-scheduler-target='chore']")
    const next = card.dataset.choreRequirePhoto !== "true"

    card.dataset.choreRequirePhoto = next

    const label = btn.querySelector(".photo-label")
    if (label) label.textContent = next ? "photo ON" : "photo off"

    btn.classList.toggle("text-green-500", next)
    btn.classList.toggle("text-red-400", !next)
  }

  // ── Photo toggle on chip (persisted via PATCH) ──────────────────────────────

  async togglePhoto(event) {
    event.stopPropagation()
    const btn  = event.currentTarget
    const chip = btn.closest("[data-scheduler-target='chip']")
    const id   = btn.dataset.assignmentId
    const next = chip.dataset.requirePhoto !== "true"

    const resp = await fetch(`/chore_assignments/${id}`, {
      method:  "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this._csrf(),
        "Accept":       "application/json"
      },
      body: JSON.stringify({ chore_assignment: { require_photo: next } })
    })

    if (resp.ok) {
      chip.dataset.requirePhoto = next
      btn.classList.toggle("text-green-500", next)
      btn.classList.toggle("text-red-400", !next)
      btn.title = next ? "Photo required — click to remove" : "Click to require photo"
    }
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
    const tempChip = this._buildChip({ id: "temp", choreName: chore.name, choreId: chore.id, requirePhoto: chore.requirePhoto })
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
            chore_id:      chore.id,
            child_id:      childId,
            scheduled_on:  date,
            require_photo: chore.requirePhoto || false
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
      // Update temp chip with the real assignment id so × deletion and 📷 toggle work
      tempChip.dataset.assignmentId = data.id
      tempChip.querySelectorAll("[data-assignment-id]").forEach(el => {
        el.dataset.assignmentId = data.id
      })

    } catch {
      tempChip.remove()
    }
  }

  // Build a chip DOM node that mirrors _chore_chip.html.erb
  _buildChip({ id, choreName, choreId, requirePhoto = false }) {
    const div = document.createElement("div")
    div.className = "chore-chip group flex items-center justify-between gap-1 bg-blue-100 text-blue-800 rounded px-1.5 py-0.5 text-xs font-medium max-w-full"
    div.dataset.schedulerTarget = "chip"
    div.dataset.assignmentId    = id
    div.dataset.choreId         = choreId
    div.dataset.requirePhoto    = requirePhoto

    const name = document.createElement("span")
    name.className   = "truncate leading-tight"
    name.textContent = choreName

    const camBtn = document.createElement("button")
    camBtn.type      = "button"
    camBtn.className = `flex-shrink-0 leading-none transition-colors ${requirePhoto ? "text-green-500" : "text-red-400"}`
    camBtn.innerHTML = `<svg class="w-3 h-3" viewBox="0 0 24 24" fill="currentColor"><path d="M12 15.2a3.2 3.2 0 100-6.4 3.2 3.2 0 000 6.4z"/><path fill-rule="evenodd" d="M9 2L7.17 4H4a2 2 0 00-2 2v12a2 2 0 002 2h16a2 2 0 002-2V6a2 2 0 00-2-2h-3.17L15 2H9zm3 15a5 5 0 110-10 5 5 0 010 10z" clip-rule="evenodd"/></svg>`
    camBtn.title       = requirePhoto ? "Photo required — click to remove" : "Click to require photo"
    camBtn.dataset.action       = "click->scheduler#togglePhoto"
    camBtn.dataset.assignmentId = id

    const removeBtn = document.createElement("button")
    removeBtn.type        = "button"
    removeBtn.textContent = "×"
    removeBtn.className   = "flex-shrink-0 ml-0.5 text-blue-400 hover:text-red-500 transition-colors leading-none opacity-100 md:opacity-0 md:group-hover:opacity-100"
    removeBtn.setAttribute("aria-label", "Remove assignment")
    removeBtn.dataset.action       = "click->scheduler#removeAssignment"
    removeBtn.dataset.assignmentId = id

    div.append(name, camBtn, removeBtn)
    return div
  }

  _choreDataFrom(card) {
    return {
      id:           card.dataset.choreId,
      name:         card.dataset.choreName,
      tokens:       card.dataset.choreTokens,
      requirePhoto: card.dataset.choreRequirePhoto === "true"
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
