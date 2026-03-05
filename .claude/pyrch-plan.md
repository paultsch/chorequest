# Pyrch — App Master Plan

> The production brand name is **Pyrch**, pronounced like "perch" (rhymes with church). Domain: **pyrch.ai**. The name is a phonetic respelling of "perch" — owls perch, Rue perches over the household. Pronunciation guide "Pyrch (rhymes with perch)" must appear on the marketing site and in all early audio content.
>
> Maintained by the `pyrch-planner` agent. Update this file as decisions are made, modules are defined, and prompts are refined.

---

## Vision

Pyrch is a family operating system — a modular platform built around the **Household** as the core unit. Parents and children in a household share a space where chores, rewards, learning, money, and schedules all connect. AI (via the owl mascot assistant Rue) is woven throughout, helping parents manage and motivating kids to engage.

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

### Rue's Capability Boundary Behavior

**Decision (confirmed):** When a parent asks Rue to do something she cannot do yet, Rue responds in character with a friendly, self-aware message rather than a flat refusal. She frames every limitation as temporary and offers to escalate it.

**Example response:** "My boss hasn't taught me how to do that yet! Want to let him know so he can add it to my skills?"

**If the parent says yes:** Rue auto-logs the request as a feedback entry on their behalf, adding it directly to the parent feedback board (the feature voting system). She then confirms: "Done! I told him. He gets the message every time someone asks me something I can't do yet, so the most-requested things get built first."

**Design rules:**
- Rue never says "I can't do that" flatly — always frame as a temporary limitation with an offer to escalate
- The feedback log entry must capture: the parent's verbatim or paraphrased request, timestamp, and the submitting parent's ID
- Rue confirms the log entry succeeded before closing the exchange
- One parent confirming escalation counts as one vote on the feedback board — if ten parents ask Rue the same thing, that item rises in the priority queue automatically

**Why this matters:** This turns Rue's gaps into a product discovery loop. Parents encounter missing features organically through conversation, and those requests flow directly into the prioritized feedback queue without any separate reporting step. The most-wanted features surface from real usage, not surveys.

**Standing requirement — Rue actions must ship with every feature:**
Every new app feature must ship with a corresponding Rue action in the same pull request. The capability boundary shrinks with every release — it should never stay the same. If a parent can do it by tapping through the UI, Rue must be able to do it by conversation. A Rue action is a discrete, well-named function exposed to the Claude API via tool use (e.g. `assign_chore`, `approve_attempt`, `grant_tokens`). Each action must have a clear description, typed parameters, and return a human-readable confirmation string that Rue can speak back. Deferring Rue actions means they never get built — this is a non-negotiable convention, not a guideline. See the "Rue-First Development Rule" section for full rationale.

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

## Rue-First Development Rule

**Non-negotiable convention:** Every time a new feature is built in Pyrch, a corresponding Rue action must be created in the same pull request. Features and Rue actions ship together, never separately.

### The Rule

When a developer builds a new piece of app functionality — a controller action, a model operation, a background job — they must also implement a callable Rue tool that covers the same functionality. Both land in the same PR. The PR is not mergeable without the Rue action.

### Why

If Rue actions are deferred, they never get built. The backlog grows, the capability boundary widens, and the AI-first design goal quietly collapses. The whole point of Pyrch is that a parent should be able to do anything in the app by talking to Rue. That is only possible if every feature has a Rue equivalent from day one — not after a sprint to "catch up" that never happens.

This also validates the feature's design: if you cannot define a clean Rue action for a feature (clear name, typed parameters, readable return string), the feature's design is probably too ambiguous. Implementing the Rue action forces clarity.

### What "a Rue action" means

A Rue action is a discrete, well-named function that the Claude API can call via tool use. It must have:
- A clear function name that reads like a command (`assign_chore`, `approve_attempt`, `grant_tokens`, `add_homework_task`, `create_event`)
- A description that Claude can use to decide when to invoke it
- Typed parameters with descriptions (e.g. `child_name: string`, `chore_name: string`, `date: ISO8601 string`)
- A human-readable return string that Rue speaks back to the parent or child ("Done — I assigned Clean Room to Emma for Friday.")
- Server-side ownership validation: the action must verify the requesting user has rights to the affected records before executing

### The checklist item

Each phase in the development plan includes a named checklist item: "Add Rue actions for all features built in this phase." It is not an afterthought — it is the last deliverable of each phase, reviewed alongside the security audit pass.

---

## Modules

### Core (always on)
- **Household management** — create household, invite co-parents, add children, manage roles
- **Token economy** — earn/spend tokens, transaction ledger, balance per child
- **Pyrch AI assistant (Rue)** — embedded in every module

### Bolt-on Modules

| Module | Description | Dependency |
|--------|-------------|------------|
| Chores | Assign chores, photo verification, AI approval | Token economy |
| Games | Earn screen time, heartbeat token deduction | Token economy |
| Homework | Track school assignments, due dates, completion | Token economy (optional) |
| Allowance | Real money tracking alongside tokens, savings goals | Token economy |
| Rewards Store | Kids spend tokens on parent-defined rewards (not just game time) | Token economy |
| Family Calendar | Shared events, pickup schedules, recurring activities | Core only |
| School Communications Hub | Aggregate school emails and SMS into one household inbox; Rue parses each message to extract the relevant child, message category (event, homework, permission slip, absence/nurse alert, newsletter, announcement), action items, and deadlines; proposes calendar entries and homework tasks with one-tap confirmation; ingestion via email forwarding to a household-specific address and a Twilio SMS number per household; child-appropriate visibility controlled by parent; third-party integrations (ClassDojo, Remind, Google Classroom) as a later phase | Family Calendar + Homework |

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
- `skip_before_action :verify_authenticity_token` must be scoped to only the specific actions that need it (heartbeat, stop) — never skip CSRF globally on a controller
- `GameSession#ended_at` is set on create — not a reliable "is active?" indicator; use explicit `stopped_early` flag
- Row-level locking (`child.with_lock`) is necessary on token deductions to prevent race conditions
- GameScores must require a `session_id` param and verify the caller owns that session — never fall back to accepting raw `child_id`/`game_id` params from untrusted callers

### Security
- **Scope everything through the household, not the individual adult** — the ChoreQuest mistake was scoping through `current_parent`; any query that takes a user-supplied ID (child_id, chore_id, game_session_id) must verify membership in `current_household` before acting on it
- **Two auth systems coexist** — adults use Devise (`authenticate_user!`, `current_user`), children use PIN-based session (`session[:child_id]`); never conflate them
- **Ownership validation pattern** — in every controller that accepts an ID param, immediately verify ownership: `current_household.children.find(params[:child_id])` raises `ActiveRecord::RecordNotFound` (rescued to 404) if the child isn't in the household; use this as the standard gate
- **Run a security pass proactively** — a dedicated security review agent found 7 pre-existing vulnerabilities in ChoreQuest in a single pass; schedule a security audit as a named step at the end of each Pyrch phase, not just after incidents
- **`find_by` vs `find`** — use `find_by` whenever the record might legitimately not exist (stale sessions, deleted records, optional lookups) to return `nil` instead of raising `RecordNotFound` and causing a 500
- **Minimum value enforcement** — always enforce server-side minimums on numeric inputs (e.g. `duration_minutes: [params.dig(...), 1].max`) regardless of what the client sends

### Testing
- Devise fixtures need `<% require 'bcrypt' %>` at the top of `parents.yml`
- Minitest 6+ is incompatible with Rails 7.1 — pin to `~> 5.25`
- Scaffold-generated tests are useless after authentication is added — delete them immediately
- `assigns()` in integration tests requires `rails-controller-testing` gem
- Write auth gate tests first (unauthenticated → redirect), then ownership tests (wrong household → 404/redirect), then happy-path tests; this order catches the most critical bugs fastest
- Test files: 4 controller test files covering auth gates, ownership validation, and UI behavior is a meaningful coverage target per phase

### Mobile / PWA
- iOS never shows an install prompt — must build a custom "Add to Home Screen" banner
- Turbo polling on child page: use `visibilitychange` event to trigger refresh on tab refocus
- `safe-area-inset-top` needed for PWA mode on iOS (status bar overlap)

### UI / UX
- **Variables computed outside a `<turbo-frame>` block are baked in at page load** and will not update when the frame polls; anything that must re-render on poll intervals must live inside the frame
- **`<details>/<summary>` for zero-JS toggles** — native HTML element; no Stimulus controller needed for simple show/hide patterns (e.g. PIN reveal, collapsible sections); prefer this over adding JS where possible
- **Play gate logic** — the correct test is `where.not(approved: true)` (chores not yet approved), not `where(completed: false)` (chores not self-marked done); children can game a `completed` flag gate without parent review
- **Age-appropriate language** — avoid institutional status language on child-facing screens; use encouraging language ("Being checked... 👀", "Try again! 🔄", "Done! ⭐") instead of system terms ("Awaiting review", "Rejected", "Completed")

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
- [ ] Establish ownership validation helper: `current_household.children.find(id)` pattern used everywhere an ID crosses a controller boundary
- [ ] Pyrch AI assistant identity: build Rue SVG character (small expressive owl, warm colors)
- [ ] Security audit: verify every controller action has auth gate + household-scoped ownership check
- [ ] Add Rue actions for all features built in this phase: `create_child` (name, pin_code, birthday), `list_children` (returns names, ages, token balances), `get_token_balance` (child_name → current balance), `grant_tokens` (child_name, amount, reason), `deduct_tokens` (child_name, amount, reason)

### Phase 2 — Chores Module
- [ ] Chore model (name, description, definition_of_done, token_amount, household)
- [ ] ChoreAssignment (child, chore, scheduled_on, require_photo, status) — unique constraint on (child_id, chore_id, scheduled_on)
- [ ] ChoreAttempt (photo, status: pending/approved/rejected, ai_message, parent_note)
- [ ] AI photo analysis job (reuse AnalyzeChorePhotoJob pattern from ChoreQuest)
- [ ] Child public page (chore list, submit photo, status updates) — all status labels use kid-friendly language
- [ ] All status-related UI inside `<turbo-frame>` so polling picks up changes
- [ ] Parent dashboard (approval queue, bulk approve, Today at a Glance)
- [ ] Drag-and-drop scheduler (port from ChoreQuest)
- [ ] Security audit: verify all ChoreAssignment and ChoreAttempt queries are scoped to `current_household`
- [ ] Add Rue actions for all features built in this phase: `assign_chore` (child_name, chore_name, date, require_photo), `list_today_assignments` (child_name → today's chores with status), `list_pending_approvals` (returns all unapproved attempts household-wide), `approve_attempt` (attempt_id or child+chore identifier), `reject_attempt` (attempt_id, reason)

### Phase 3 — Games Module
- [ ] Game model + GameSession with heartbeat (port from ChoreQuest)
- [ ] Heartbeat + stop actions: `skip_before_action :verify_authenticity_token, only: [:heartbeat, :stop]`
- [ ] Heartbeat + stop actions: verify game session ownership via `current_household` even though auth is skipped
- [ ] GameScore: require `session_id`, verify caller owns the session — never accept raw `child_id`/`game_id`
- [ ] Pyrch games platform (Berry Hunt + new games)
- [ ] Child play gate: gate on `where.not(approved: true)` — not `completed: false`
- [ ] Play button and token balance inside `<turbo-frame>` so polling updates them
- [ ] Security audit: verify all GameSession queries are scoped to `current_household`
- [ ] Add Rue actions for all features built in this phase: `check_play_eligibility` (child_name → eligible yes/no with reason), `start_game_session` (child_name, game_name, duration_minutes), `list_available_games` (returns games the household has enabled), `get_game_session_status` (child_name → active session details or none)

### Phase 4 — Homework Module
- [ ] HomeworkTask (title, subject, due_date, points, child, household)
- [ ] Completion tracking + token reward on completion
- [ ] Pip AI: suggest study time, celebrate streaks
- [ ] Add Rue actions for all features built in this phase: `add_homework_task` (child_name, title, subject, due_date, points), `list_homework_due` (child_name, optional date range → tasks with due dates and status), `mark_homework_done` (child_name, task_title → marks complete and awards tokens), `get_homework_summary` (child_name → all open tasks grouped by subject)

### Phase 5 — Allowance Module
- [ ] AllowanceRule (weekly amount, pay day, child)
- [ ] RealMoneyTransaction (amount, type: earned/spent/saved, description)
- [ ] Savings goal tracking
- [ ] Pip AI: saving advice for kids, spending pattern alerts for parents
- [ ] Add Rue actions for all features built in this phase: `get_allowance_balance` (child_name → real money balance and last pay date), `set_allowance_rule` (child_name, weekly_amount, pay_day), `log_money_transaction` (child_name, amount, type: earned/spent/saved, description), `get_savings_goal_progress` (child_name → goal name, target, current balance, percent complete)

### Phase 6 — Rewards Store
- [ ] Reward model (name, token_cost, household, image)
- [ ] RewardRedemption (child, reward, redeemed_at, approved_by)
- [ ] Parent approves redemptions
- [ ] Pip AI: suggest rewards based on child interests and spending patterns
- [ ] Add Rue actions for all features built in this phase: `list_rewards` (returns all household rewards with token costs and availability), `get_redemption_queue` (returns pending redemptions awaiting parent approval), `approve_redemption` (child_name, reward_name → marks approved and deducts tokens), `reject_redemption` (child_name, reward_name, reason), `add_reward` (name, token_cost — lets a parent create a new reward by conversation)

### Phase 7 — Family Calendar
- [ ] Event model (title, start_at, end_at, household, created_by)
- [ ] Recurring events
- [ ] Child-visible vs adult-only events
- [ ] Pip AI: spot schedule conflicts, remind about upcoming events
- [ ] Add Rue actions for all features built in this phase: `create_event` (title, start_at, end_at, child_name optional, adult_only boolean), `list_upcoming_events` (optional date range, optional child_name → events visible to that member), `delete_event` (event_id or title + date), `check_schedule_conflicts` (date → returns any overlapping events for the household)

### Phase 8 — School Communications Hub
- [ ] **Household inbox address provisioning** — each household gets a dedicated forwarding address (e.g. `smithfamily@inbox.pyrch.app`); use a service like Mailgun or Postmark inbound routing to POST raw email payloads to a Pyrch webhook endpoint
- [ ] **Twilio SMS number per household** — provision a Twilio number on household creation; incoming texts POST to a webhook; store raw SMS payload the same way as email
- [ ] **Message model** — fields: `source` (enum: email, sms, manual), `raw_content` (text), `parsed_summary` (text), `child_id` (nullable FK — nil if not yet attributed or household-wide), `category` (enum: event, homework, permission_slip, absence_alert, newsletter, announcement, unknown), `action_item` (boolean), `deadline` (date, nullable), `actioned` (boolean, default false), `adult_only` (boolean, default false), `household_id`
- [ ] **Rue parsing job** — background job triggered on every new inbound message; calls Claude API with the raw content; prompt instructs Rue to return structured JSON: `{ child_name, category, summary, action_item, deadline, adult_only, proposed_calendar_event, proposed_homework_task }`; job writes parsed fields back to the Message record and enqueues proposal notifications
- [ ] **Inbox UI** — unified communication feed scoped to `current_household`; filter by child, category, and unread/actioned state; archive view for newsletters and one-way announcements; action items surfaced in a separate "needs attention" section at the top; parent can tap any message and ask Rue follow-up questions in context
- [ ] **Calendar integration** — when Rue's parsing job detects a proposed calendar event, create a pending `CalendarEventProposal` record; surface it in the inbox as a one-tap confirmation: "I found a field trip on March 15th — add it to the family calendar?"; confirming creates the `Event` via the Family Calendar module
- [ ] **Homework integration** — when Rue detects a homework mention, create a pending `HomeworkProposal` record; surface it the same way: "The email mentions a science project due Friday for Jake — add it to his homework tracker?"; confirming creates the `HomeworkTask` via the Homework module
- [ ] **Child visibility** — parent controls `adult_only` flag per message; child-facing views show only messages where `adult_only: false`; Rue generates a child-appropriate summary for visible messages (age-appropriate language, no administrative/billing content)
- [ ] **Manual entry** — parent can paste a message body or type a plain-text summary; same Rue parsing job runs on it; source set to `manual`
- [ ] **Future: third-party integrations** — ClassDojo, Remind, and Google Classroom OAuth integrations; these require individual OAuth app approvals and are explicitly deferred; design the Message ingestion pipeline to accept an additional `source` enum value (`class_dojo`, `remind`, `google_classroom`) so adding them later is additive only
- [ ] Security audit: verify all Message queries are scoped to `current_household`; webhook endpoints must validate the Mailgun/Twilio signature before processing any payload
- [ ] Add Rue actions for all features built in this phase: `check_school_inbox` (optional child_name, optional category → returns unactioned messages needing attention), `get_message_detail` (message_id → full summary and proposed actions), `action_message` (message_id → marks actioned), `confirm_calendar_proposal` (proposal_id → creates the calendar Event), `confirm_homework_proposal` (proposal_id → creates the HomeworkTask), `dismiss_proposal` (proposal_id, type: calendar or homework → discards without creating)

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
Household is the security boundary — scope ALL queries through current_household; never query ChoreAssignment, Child, or Chore by raw ID without first verifying household membership (use current_household.children.find(id), which raises RecordNotFound on mismatch).
Adults use Devise (authenticate_user!, current_user). Children use PIN session (session[:child_id]). Never conflate them.
ChoreAssignment has unique constraint on (child_id, chore_id, scheduled_on).
AI photo analysis runs as a background job using the Anthropic gem. "Inconclusive" AI results escalate to human review, not auto-reject.
Child-facing status labels must use kid-friendly language ("Being checked...", "Try again!", "Done!"), not system terms.
All dynamic child-page content (play gate, token balance, chore status) must live inside a <turbo-frame> so polling updates it.
Play gate uses where.not(approved: true), not where(completed: false).
Read .claude/pyrch-plan.md for full context.
Build Phase 2: Chore, ChoreAssignment, ChoreAttempt, AI analysis job, child public page, parent dashboard. End with security audit pass.
```

### Starting Phase 3 (Games Module)
```
Pyrch app — Phases 1 and 2 complete. Now building the Games module.
Household is the security boundary — scope all GameSession queries through current_household.
Heartbeat and stop actions are called from static HTML game files and cannot send CSRF tokens. Use: skip_before_action :verify_authenticity_token, only: [:heartbeat, :stop] — but still verify game session ownership via current_household in those actions.
GameScore creation requires a session_id param; verify the caller owns that session. Never fall back to accepting raw child_id or game_id from untrusted callers.
Children use PIN session (session[:child_id]), not Devise.
Play gate: use where.not(approved: true) on chore assignments, not completed: false.
Play button and token balance must be inside the <turbo-frame> polling block so they update without a full page reload.
Row-level locking (child.with_lock) is required on token deductions to prevent race conditions.
Read .claude/pyrch-plan.md for full context.
Build Phase 3: Game, GameSession, heartbeat, GameScore, child play gate, Berry Hunt integration. End with security audit pass.
```

### Starting Phase 8 (School Communications Hub)
```
Pyrch app — Phases 1–7 complete. Now building the School Communications Hub module.
Household is the security boundary — scope ALL Message queries through current_household.
Ingestion has two paths: (1) inbound email webhook (Mailgun or Postmark) POSTs raw email to /webhooks/inbound_email; (2) Twilio SMS webhook POSTs to /webhooks/inbound_sms. Both endpoints must validate the provider's request signature before processing. Store raw payload, then enqueue a RueParseMessageJob.
RueParseMessageJob calls the Claude API with the raw message content and returns structured JSON: { child_name, category, summary, action_item, deadline, adult_only, proposed_calendar_event, proposed_homework_task }. Write parsed fields back to the Message record.
Message model fields: source (enum: email, sms, manual), raw_content, parsed_summary, child_id (nullable), category (enum: event, homework, permission_slip, absence_alert, newsletter, announcement, unknown), action_item (boolean), deadline (date nullable), actioned (boolean), adult_only (boolean), household_id.
Calendar integration: proposed events become CalendarEventProposal records surfaced as one-tap confirmations in the inbox; confirming creates a Family Calendar Event.
Homework integration: proposed assignments become HomeworkProposal records surfaced the same way; confirming creates a HomeworkTask.
Child visibility: adult_only messages are hidden from child-facing views; Rue generates age-appropriate summaries for visible messages.
Third-party integrations (ClassDojo, Remind, Google Classroom) are explicitly out of scope for this phase — design the source enum to accept them later without schema changes.
Read .claude/pyrch-plan.md for full context.
Build Phase 8: household inbox provisioning, Twilio SMS setup, Message model, RueParseMessageJob, inbox UI with filters, calendar and homework proposal flows, child visibility controls. End with security audit pass.
```

---

## Open Decisions

- [x] **App name** — Decided: **Prych** (pronounced "perch"; phonetic respelling; domain prych.ai; the spelling ties to owl mascot perching behavior without being a dictionary word, making it trademarkable)
- [x] **Mascot name** — Decided: **Rue** (small expressive owl; "rue" = to reflect/think carefully)
- [x] **Primary tagline** — Decided: "The family app that runs itself." Secondary/chores-module hook: "No more nagging. Just Prych."
- [x] **Brand relationship** — Prych is the platform noun; Rue is the AI personality. Parents recommend "Prych" to friends; kids interact with "Rue" directly. Mirrors Apple/Siri structure.
- [x] **Logo direction** — Prych wordmark should incorporate a subtle perching visual (small owl silhouette or lettermark styled to suggest wings or a branch); the owl/perch connection should be baked into the logo without requiring explanation
- [ ] **Trademark search** — REQUIRED before any logo design or legal entity formation: USPTO search for "Prych" in Class 42 (SaaS) and Class 41 (education/entertainment for children)
- [ ] **Pronunciation rollout** — "Prych (rhymes with perch)" must appear on the landing page near the logo, in onboarding emails, in any audio content, and in the app store description until brand awareness is established
- [ ] **Module pricing** — free tier? All modules free? Subscription unlocks advanced AI features?
- [ ] **Child age cutoff** — at what age does a "child" become an adult in the system? (e.g. 18 → automatically upgrade to adult member)
- [ ] **Multi-household children** — full support from day 1 or defer to later phase?
- [ ] **Mobile-first or responsive** — PWA from the start, or web-first with PWA added later?
