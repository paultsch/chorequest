# Current Sprint — "Make It Solid"

> Last updated: 2026-03-02 by project-manager agent

## This Week's Focus
Fix the three bugs actively breaking trust and security on the live app. All are small-effort, high-impact, ship together.

---

## B1 — Security: Data Leak ~~(CRITICAL)~~ ✅ Already Fixed
**File:** `app/controllers/chore_assignments_controller.rb`
**Status:** The query was already moved and scoped during the scheduler refactor. `@selected_child` is derived from `current_parent.children`, and all queries chain off it. No code change needed.

## B2 — Play Gate Bypass (CRITICAL)
**Bug:** The "Play Games" gate on `children/show` checks `completed: true` instead of `approved: true` — kids can self-mark chores done and unlock games without parent review.
**Fix:** Change the gate condition from `completed:` to `approved:`.

## B3 — Parent Mobile Nav Broken (HIGH)
**File:** `app/views/layouts/application.html.erb`
**Bug:** The `data-nav-target="menu"` dropdown block is missing from the parent signed-in nav section — logged-in parents on mobile have zero navigation.
**Fix:** Add the missing menu block to the signed-in parent nav section.

---

## After B1–B3
Next up: B4 (Child Play button nav sync), Item 4 (child status language), Item 5 (child progress bar), Item 6 (sign-in error styling).
Full prioritized backlog: run the `project-manager` agent or see `CLAUDE.md` Ideas Backlog.
