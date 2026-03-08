# Current Sprint — "Chore Oversight + Sub-Tasks"

> Last updated: 2026-03-08 by primary-developer agent
> Previous sprint "Polish the Child Experience" complete — items 4, 5, B4, PIN visibility, School Hub done.

---

## ✅ DONE — Features 3C: Model Photos + Per-Step Submission + Rue Task Suggestions

### Migration applied (both dev and test databases)
- `db/migrate/20260308100000_add_chore_task_id_to_chore_attempts.rb` — adds nullable `chore_task_id` FK to `chore_attempts` (index + foreign key)

### Model changes
- `app/models/chore.rb` — added `has_one_attached :model_photo`
- `app/models/chore_task.rb` — added `has_one_attached :model_photo`
- `app/models/chore_attempt.rb` — `chore_task_id` now accepted via association (belongs_to :chore_task, optional)

### Controller changes
- `app/controllers/chores_controller.rb` — added `suggest_tasks` action (POST, Anthropic API call, returns JSON array); updated `chore_params` to permit `:model_photo` at chore level and `:model_photo` inside `chore_tasks_attributes`
- `app/controllers/chore_attempts_controller.rb` — `create` now accepts `chore_task_id`; `approve` and `bulk_approve` use `all_required_tasks_approved?` helper before marking assignment approved/granting tokens; new private helper `all_required_tasks_approved?`
- `app/controllers/public_controller.rb` — `create_attempt` accepts `chore_task_id`; `new_attempt` uses per-task pending check (not blanket); `create_attempt` uses scoped duplicate detection per task vs whole-chore
- `app/jobs/analyze_chore_photo_job.rb` — per-step mode: if `attempt.chore_task_id` present, narrows prompt to that task's title and includes task's model photo as reference image; whole-chore mode: includes chore-level model photo; `all_required_tasks_approved?` helper before granting tokens on AI APPROVED

### View changes
- `app/views/chores/_form.html.erb` — task section wrapped in `<details>` expander ("Break it into steps (optional)"); chore-level model photo upload added above the expander; task rows now include photo_required checkbox + model photo file input; "Suggest steps with Rue" button wired to `chore-tasks#suggestTasks`; form is now `multipart: true`
- `app/views/public/show.html.erb` — full per-step submission flow: chores with `photo_required` tasks show individual step cards (status badge, model photo thumbnail, child's submitted photo vs reference comparison, per-step upload form); simple chores retain original flow + show chore model photo if present
- `app/views/chore_attempts/new.html.erb` — shows task title in header when `chore_task_id` in params; shows task model photo (or chore model photo as fallback) above the upload field

### JS changes
- `app/javascript/controllers/chore_tasks_controller.js` — added `suggestTasks` async action: reads `#chore_name`, POSTs to `/chores/suggest_tasks`, adds each returned title as a new task row; spinner + loading state on the Suggest button; error display on failure

### Route changes
- `config/routes.rb` — added `post 'chores/suggest_tasks', to: 'chores#suggest_tasks', as: :suggest_tasks_chores` (before `resources :chores` so it routes correctly)

---

## ✅ DONE — Features 3A + 3B: Chore Oversight and ChoreTask Sub-Chores

### Migrations applied (both dev and test databases)
- `db/migrate/20260307100000_add_frequency_days_to_chores.rb` — adds `frequency_days:integer` (nullable) to chores
- `db/migrate/20260307100100_create_chore_tasks.rb` — new `chore_tasks` table: chore_id, title, position, photo_required, timestamps; index on (chore_id, position)

### Model changes
- `app/models/chore.rb` — added `has_many :chore_tasks, -> { order(:position) }, dependent: :destroy` and `accepts_nested_attributes_for :chore_tasks, allow_destroy: true, reject_if: :all_blank`
- `app/models/chore_task.rb` — new model: belongs_to :chore, validates title presence and position numericality

### Controller changes
- `app/controllers/chores_controller.rb` — `chore_params` now permits `:frequency_days` and `chore_tasks_attributes: [:id, :title, :position, :photo_required, :_destroy]`
- `app/controllers/chore_oversight_controller.rb` — new controller: `authenticate_parent!`, computes last_completed_on, due_on, days_until_due, status per chore, sorts overdue first

### View changes
- `app/views/chores/_form.html.erb` — added frequency_days input field + full inline task list section with Stimulus `chore-tasks` controller (add row, remove row, up/down reorder, `<template>` for new rows)
- `app/views/chores/edit.html.erb` — replaced bare scaffold with styled card layout
- `app/views/chores/index.html.erb` — added "Chore Health" amber button linking to `chore_oversight_path`
- `app/views/chore_oversight/index.html.erb` — new view: mobile cards + desktop table showing chore health (last completed, frequency, due date, status badge); links to Edit and Assign per chore
- `app/views/chore_oversight/_status_badge.html.erb` — status badge partial (Overdue/Due Soon/OK/No Schedule)
- `app/views/public/show.html.erb` — today's chore cards now show ordered task checklist when `chore.chore_tasks.any?`; also fixed "Mom is checking" → "Your grownup is checking" in both today and upcoming sections

### JS changes
- `app/javascript/controllers/chore_tasks_controller.js` — new Stimulus controller for inline task list; auto-discovered via eagerLoadControllersFrom

### Job changes
- `app/jobs/analyze_chore_photo_job.rb` — when chore has chore_tasks, injects numbered task list into the Claude prompt; falls back to original prompt if no tasks; V2 TODO comment added for per-task photo submission

### Rue tool changes
- `app/controllers/rue_controller.rb` — added `get_chore_health` tool: returns status for all chores (last completed, frequency, days overdue); updated system prompt to mention the new capability

### Route changes
- `config/routes.rb` — added `get 'chore_oversight', to: 'chore_oversight#index', as: :chore_oversight`

---

## Previous Sprint Items (still valid, carried forward)

### ✅ DONE — Item 4: Child Status Language
`app/views/children/show.html.erb` — replaced all status labels: "Awaiting review" → "Being checked... 👀", "Rejected" → "Try again! 🔄", "Completed ✓" → "Done! ⭐"

### ✅ DONE — Item 5: Sign-in Error Styling
`flash[:alert]` already rendered globally — no code change needed.

### ✅ DONE — B4: Child Play Button Nav Sync
`app/views/public/show.html.erb` — moved `render 'bottom_nav'` inside the turbo-frame.

### ✅ DONE — PIN Code Visibility
`app/views/children/index.html.erb` — Show/Hide toggle via `<details>/<summary>`.

### ✅ DONE — School Communications Hub POC
School email forwarding, parsing, and inbox UI — see previous sprint for details.

---

## After This Sprint
Next priorities: confetti celebration animation on chore approval, photo preview before submission, AI status language ("AI is checking...") during pending analysis, parent Settings page redesign.
