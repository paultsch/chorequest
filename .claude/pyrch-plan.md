# Pyrch — App Master Plan

> Maintained by the `pyrch-planner` agent. Update this file as decisions are made, modules are defined, and prompts are refined.

---

## Vision

Pyrch is a family operating system — a modular platform built around the **Household** as the core unit. Parents and children in a household share a space where chores, rewards, learning, money, and schedules all connect. AI (via the owl mascot assistant) is woven throughout, helping parents manage and motivating kids to engage.

ChoreQuest is the prototype that proved the core loop works. Pyrch is the production app built right from the start.

---

## Mascot & AI Identity

**Character:** A small, expressive cartoon owl
**Name: Rue** ✓ *decided*
- Short, easy for kids to say, sticks in the mind
- Double meaning: "Rue" as a name is warm and distinctive; "to rue" means to reflect and think carefully — fitting for a wise owl AI
- All AI assistant copy throughout the app uses: "Ask Rue", "Rue suggests...", "Rue is thinking...", "Rue says..."
- Owl = wisdom + night vision (sees things others miss) — great metaphor for an AI that "sees" patterns in the family's data

**AI assistant role:**
- Visible to parents: suggests chores to assign, flags patterns (chore always skipped, token balance running low), recommends rewards, summarizes the week
- Visible to children: encourages, celebrates completions, gives hints on homework tasks, age-appropriate feedback
- Baked into the app — not an add-on. Every module has Rue touchpoints.

---

## Tech Stack

| Layer | Decision | Notes |
|-------|----------|-------|
| Framework | Rails 7.1 | Proven in ChoreQuest prototype |
| Database | PostgreSQL | |
| Frontend | Tailwind CSS + Hotwire (Turbo + Stimulus) | No JS framework |
| Auth | Devise (adults) + PIN/token (children) | Same pattern as ChoreQuest |
| AI | Anthropic Claude API (via `anthropic` gem) | Already integrated in ChoreQuest |
| Jobs | ActiveJob (async adapter) | Upgrade to Sidekiq when needed |
| File storage | ActiveStorage | Photos, avatars |
| Deployment | Render.com + PostgreSQL | Same as ChoreQuest |

---

## Core Architecture: The Household

Everything in Pyrch belongs to a **Household**. This is the fundamental departure from ChoreQuest where `Parent` was the root owner.

### Data Model

```
Household
  has_many :household_memberships
  has_many :adults, through: :household_memberships, source: :user, conditions: {role: ['owner','co-parent','guardian']}
  has_many :children, through: :household_memberships, source: :user, conditions: {role: 'child'}

HouseholdMembership
  belongs_to :household
  belongs_to :user
  role: enum [owner, co_parent, guardian, child]
  status: enum [active, invited, suspended]

User (single model for all humans — replaces separate Parent/Child split)
  type/role handled by HouseholdMembership
  Adults: email + password (Devise)
  Children: PIN + public token (no email required)
```

### Key Architectural Decisions

1. **Single `User` model** — adults and children are both users, distinguished by their `HouseholdMembership` role. Avoids the awkward `Parent`/`Child` model split in ChoreQuest.
2. **Household is the security boundary** — all data is scoped to `current_household`, never to an individual parent. Co-parents see the same data.
3. **Invitation system** — adults join a household via email invite. Children are created directly within a household (no email needed).
4. **A child CAN belong to multiple households** — for blended/split families. Each household sees only their own data for that child.
5. **Module feature flags** — each module (chores, games, homework, allowance, calendar) can be enabled/disabled per household.

---

## Modules

### Core (always on)
- **Household management** — create household, invite co-parents, add children, manage roles
- **Token economy** — earn/spend tokens, transaction ledger, balance per child
- **Pyrch AI assistant (Pip)** — embedded in every module

### Bolt-on Modules

| Module | Description | Dependency |
|--------|-------------|------------|
| Chores | Assign chores, photo verification, AI approval | Token economy |
| Games | Earn screen time, heartbeat token deduction | Token economy |
| Homework | Track school assignments, due dates, completion | Token economy (optional) |
| Allowance | Real money tracking alongside tokens, savings goals | Token economy |
| Rewards Store | Kids spend tokens on parent-defined rewards (not just game time) | Token economy |
| Family Calendar | Shared events, pickup schedules, recurring activities | Core only |

---

## Lessons Learned from ChoreQuest (Apply to Pyrch)

### Architecture
- **Don't root everything under `Parent`** — the household is the right security boundary
- **Use a single polymorphic User model** — the Parent/Child split caused friction everywhere
- **Plan the unique constraints early** — ChoreAssignment's `(child_id, chore_id, scheduled_on)` constraint caught us off guard in tests
- **Turbo Frame `src` auto-fetches** — never put inline content AND `src` on the same turbo-frame; it auto-replaces on mount
- **Links inside turbo-frames need `data-turbo-frame="_top"`** if they navigate away from the frame context

### AI Integration
- AI photo analysis runs as a background job (`AnalyzeChorePhotoJob`) — this is the right pattern; keep it
- The AI prompt needs to know what "done" looks like — the `definition_of_done` field on Chore is essential
- AI confidence levels matter — "inconclusive" should escalate to human review, not auto-reject

### Token/Game System
- Heartbeat endpoint must skip CSRF verification (static HTML files can't access Rails session)
- `GameSession#ended_at` is set on create — not a reliable "is active?" indicator; use explicit `stopped_early` flag
- Row-level locking (`child.with_lock`) is necessary on token deductions to prevent race conditions

### Testing
- Devise fixtures need `<% require 'bcrypt' %>` at the top of `parents.yml`
- Minitest 6+ is incompatible with Rails 7.1 — pin to `~> 5.25`
- Scaffold-generated tests are useless after authentication is added — delete them immediately
- `assigns()` in integration tests requires `rails-controller-testing` gem

### Mobile / PWA
- iOS never shows an install prompt — must build a custom "Add to Home Screen" banner
- Turbo polling on child page: use `visibilitychange` event to trigger refresh on tab refocus
- `safe-area-inset-top` needed for PWA mode on iOS (status bar overlap)

---

## Development Phases

### Phase 1 — Core Foundation
- [ ] New Rails app: `rails new pyrch`
- [ ] Single `User` model with Devise (email/password for adults, PIN for children)
- [ ] `Household` model + `HouseholdMembership` (role enum: owner, co_parent, guardian, child)
- [ ] Household creation flow (sign up → name your household → add first child)
- [ ] Invitation system (invite co-parent via email)
- [ ] Child PIN login + public token URL (same pattern as ChoreQuest)
- [ ] Token economy (TokenTransaction model, balance computed from ledger)
- [ ] Pyrch AI assistant identity: build Rue SVG character (small expressive owl, warm colors)

### Phase 2 — Chores Module
- [ ] Chore model (name, description, definition_of_done, token_amount, household)
- [ ] ChoreAssignment (child, chore, scheduled_on, require_photo, status)
- [ ] ChoreAttempt (photo, status: pending/approved/rejected, ai_message, parent_note)
- [ ] AI photo analysis job (reuse AnalyzeChorePhotoJob pattern from ChoreQuest)
- [ ] Child public page (chore list, submit photo, status updates)
- [ ] Parent dashboard (approval queue, bulk approve, Today at a Glance)
- [ ] Drag-and-drop scheduler (port from ChoreQuest)

### Phase 3 — Games Module
- [ ] Game model + GameSession with heartbeat (port from ChoreQuest)
- [ ] Pyrch games platform (Berry Hunt + new games)
- [ ] Child play gate (chores approved → unlock games)

### Phase 4 — Homework Module
- [ ] HomeworkTask (title, subject, due_date, points, child, household)
- [ ] Completion tracking + token reward on completion
- [ ] Pip AI: suggest study time, celebrate streaks

### Phase 5 — Allowance Module
- [ ] AllowanceRule (weekly amount, pay day, child)
- [ ] RealMoneyTransaction (amount, type: earned/spent/saved, description)
- [ ] Savings goal tracking
- [ ] Pip AI: saving advice for kids, spending pattern alerts for parents

### Phase 6 — Rewards Store
- [ ] Reward model (name, token_cost, household, image)
- [ ] RewardRedemption (child, reward, redeemed_at, approved_by)
- [ ] Parent approves redemptions
- [ ] Pip AI: suggest rewards based on child interests and spending patterns

### Phase 7 — Family Calendar
- [ ] Event model (title, start_at, end_at, household, created_by)
- [ ] Recurring events
- [ ] Child-visible vs adult-only events
- [ ] Pip AI: spot schedule conflicts, remind about upcoming events

---

## Bootstrap Prompts

Use these prompts to start each phase with Claude Code:

### Starting Phase 1 (Core Foundation)
```
We are building Pyrch — a modular family management app. Rails 7.1, PostgreSQL, Tailwind, Hotwire.
Core concept: a Household has many members (adults + children) via HouseholdMembership.
Adults use Devise (email/password). Children use PIN + public token URL.
Token economy: TokenTransaction ledger, balance = sum of amounts per child.
Read .claude/pyrch-plan.md for full architecture before starting.
Build Phase 1: User model, Household, HouseholdMembership, household creation flow, token economy.
```

### Starting Phase 2 (Chores Module)
```
Pyrch app — Phase 1 complete. Now building the Chores module.
Household is the security boundary (scope all queries through current_household).
ChoreAssignment has unique constraint on (child_id, chore_id, scheduled_on).
AI photo analysis runs as a background job using the Anthropic gem.
Read .claude/pyrch-plan.md for full context.
Build Phase 2: Chore, ChoreAssignment, ChoreAttempt, AI analysis job, child public page, parent dashboard.
```

---

## Open Decisions

- [x] **Mascot name** — Decided: **Rue** (small expressive owl; "rue" = to reflect/think carefully)
- [ ] **Module pricing** — free tier? All modules free? Subscription unlocks advanced AI features?
- [ ] **Child age cutoff** — at what age does a "child" become an adult in the system? (e.g. 18 → automatically upgrade to adult member)
- [ ] **Multi-household children** — full support from day 1 or defer to later phase?
- [ ] **Mobile-first or responsive** — PWA from the start, or web-first with PWA added later?
