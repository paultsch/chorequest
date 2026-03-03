# Current Sprint — "Lock the Doors"

> Last updated: 2026-03-02 by project-manager agent (all S1–S4, H1, H2 marked done)
> Security-reviewer confirmed all fixes PASS. Only M1 remains open.

---

## 🔴 CRITICAL SECURITY — Fix Immediately (live app exposure)

### ✅ S1 — ChildrenController: No Authentication — DONE
**Bug:** `ChildrenController` was missing `authenticate_parent!` — unauthenticated users could `GET /children`, `GET /children/new`, and `POST /children`.
**Fix applied:** Added `before_action :authenticate_parent!` at class level in `app/controllers/children_controller.rb` (line 2).

### ✅ S2 — TokenTransactionsController: No Authentication — DONE
**Bug:** Any unauthenticated HTTP client could `POST /token_transactions` with an arbitrary `child_id` and `amount`.
**Fix applied:** Added `before_action :authenticate_parent!` at class level; added `child_id` ownership check in `create` — `app/controllers/token_transactions_controller.rb`.

### ✅ S3 — GameSessionsController: No Authentication + Unscoped Lookups — DONE
**Bug:** No auth guard, unscoped `GameSession.find`, user-controlled `child_id` in `create`.
**Fix applied:** Added `authenticate_parent!` for all parent-facing actions; `set_game_session` now scopes parent actions to `current_parent.children` and verifies child session ownership for `heartbeat`/`stop`; `create` validates `child_id` ownership — `app/controllers/game_sessions_controller.rb`.

### ✅ S4 — ChoreAssignmentsController: Missing Auth + Child Ownership Check — DONE
**Bug:** Missing `authenticate_parent!`; `create` accepted any `child_id` from params.
**Fix applied:** Added `before_action :authenticate_parent!` at class level; added `child_id` ownership validation in `create` alongside existing chore ownership check — `app/controllers/chore_assignments_controller.rb`.

---

## 🟠 HIGH — Fix This Week

### ✅ H1 — GameSessionsController: Free Session via duration_minutes=0 — DONE
**Bug:** `create` accepted user-controlled `duration_minutes` with no minimum — submitting `0` created a free session.
**Fix applied:** Enforced `duration_minutes >= 1` before token deduction in `app/controllers/game_sessions_controller.rb`.

### ✅ H2 — Layout: Child.find Raises 500 on Deleted Child — DONE
**Bug:** `application.html.erb` called `Child.find(session[:child_id])` which raises 500 if the child was deleted.
**Fix applied:** Changed to `Child.find_by(id: session[:child_id])` inline in the `elsif` condition; stale session cleared in the `else` branch — `app/views/layouts/application.html.erb`.

### ✅ B2 — Play Gate Bypass — DONE
**Fix applied:** Changed `where(completed: [false, nil])` to `where.not(approved: true)` in both:
- `app/controllers/children_controller.rb` (line 32)
- `app/views/children/show.html.erb` (line 146)

### ✅ B3 — Parent Mobile Nav Broken — DONE
**Fix applied:** Added the missing `data-nav-target="menu"` dropdown block to the parent signed-in section of `app/views/layouts/application.html.erb`.

---

## 🟡 MEDIUM

### ✅ M1 — GameScoresController: Unauthenticated Score Submissions — DONE
**Bug:** `GameScoresController#create` accepted unauthenticated score submissions with arbitrary `child_id` and `game_id` params, allowing score poisoning for any child.
**Fix applied:** Removed the fallback `child_id`/`game_id` path entirely. Scores now require a `session_id`, and the caller must be authorized (matching `session[:child_id]` or owning parent) — `app/controllers/game_scores_controller.rb`.

---

## Confirmed Fixed (no code change needed this sprint)

### ✅ B1 — Data Leak: Unscoped ChoreAssignment Query — DONE (prior sprint)
**Status:** Confirmed fixed during a previous scheduler refactor — query is now scoped to `current_parent`. No further action required.

---

## After This Sprint
Next up: child status language, sign-in error styling, child Play button nav sync, hide PIN codes.
Full prioritized backlog: run the `project-manager` agent or see `CLAUDE.md` Ideas Backlog.
