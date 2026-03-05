# Pyrch V2 — App Master Plan

> **Pyrch** (pronounced like "perch" — rhymes with church). Domain: **pyrch.ai**.
>
> This document supersedes the original `pyrch-plan.md` and incorporates lessons from ChoreQuest, four AI agent review reports, and a full backlog synthesis. It is the authoritative source of truth for building Pyrch V2 from scratch.
>
> Maintained by the `pyrch-planner` agent. Update as decisions are made, phases are completed, and lessons are learned.

---

## CRITICAL TERMINOLOGY — Read Before Touching Any Model, Controller, or Auth Code

There are **three completely separate account types** in Pyrch. They live in separate database tables, use separate authentication systems, and must never be conflated. Every agent and developer working on this codebase must know this cold before writing a single line.

| Account Type | Rails Model | DB Table | Auth Method | Purpose |
|---|---|---|---|---|
| **Superadmin** | `AdminUser` | `admin_users` | Devise (separate installation) | Operates the pyrch.ai platform — the founder/developer. Sees all households, manages subscriptions, controls feature flags, reviews feedback. NOT a household member. |
| **User** | `User` | `users` | Devise (email + password) | An adult household member — could be a parent, grandparent, nanny, au pair, or any trusted adult. Always a real person with an email address. |
| **Child** | `Child` | `children` | PIN + `public_token` session (NOT Devise) | A child household member. No email required. Never touches Devise routes. |

### Role Vocabulary

Within a `Household`, a `User` has one of two roles via `HouseholdMembership`:

| Role | Who | What they can do |
|---|---|---|
| `household_admin` | The managing adult(s) — typically the parent(s) who set up the account | Full household access: chores, approvals, tokens, members, billing, settings, household deletion. Multiple `household_admin`s allowed. Minimum 1 required at all times. |
| `adult_member` | Other trusted adults — grandparents, nannies, au pairs, older siblings promoted from Child | Full household content access (assign chores, approve photos, grant tokens) but NO access to billing, household settings, or member role management. |

### The Naming Rules (Enforced in All Agent Prompts and PR Reviews)

- **"Admin"** without a qualifier always means `AdminUser` (the platform operator). Never use "admin" to describe a household's managing parent.
- **"Household admin"** means a `User` with `household_admin` role. Two words, always.
- **"User"** in code means an adult household member (`User` model). Children are never called "users."
- **"Child"** means the `Child` model. Never refer to a `Child` as a "user."
- **"Member"** (generic) can refer to anyone in a household (User or Child).
- The `Admin::` Rails namespace is exclusively for `AdminUser`-authenticated superadmin views. It is never used for household management.

### When an agent is asked to "build an admin page": STOP and confirm — does the requester mean the platform superadmin (`Admin::` namespace, `AdminUser` auth) or household management for a `User`? These are completely different things. Ask before building.

---

## Vision

Pyrch is a **family operating system** — a modular platform built around the **Household** as the core unit. Parents and children in a household share a space where chores, rewards, learning, money, and schedules all connect. AI (via the owl mascot Rue) is woven throughout every module.

ChoreQuest proved the core loop works. Pyrch is the production app built right — secure, mobile-first, and AI-native from day one.

---

## Brand & Identity

### Name
**Pyrch** ✓ *decided* — phonetic respelling of "perch." The name ties to the owl mascot (owls perch) without being a dictionary word, making it trademarkable.

- Pronunciation guide "Pyrch (rhymes with perch)" must appear: near the logo on the marketing site, in the app footer, in all early audio content, and in any app store description
- Domain: **pyrch.ai**
- Never spell it "Prych" — the correct spelling has Y before R: **P-Y-R-C-H**

### Mascot: Rue
A small, expressive cartoon owl. Warm colors. Short, easy for kids to say.
- All AI copy: "Ask Rue", "Rue suggests...", "Rue is thinking...", "Rue says...", "Rue approved Emma's chore"
- Never use "AI" where "Rue" can be substituted in user-facing copy
- Double meaning: Rue as a name is warm and distinctive; "to rue" means to reflect carefully — fitting for a wise owl that "sees" patterns in family data

### Brand Voice Guide (required before Phase 2 copy is finalized)
- **For parents:** Plain declarative sentences. No jargon. Confident but not preachy. "Emma finished her chores. She earned 20 tokens." Not "Your child has successfully completed their assigned tasks."
- **For children:** Warm, encouraging, slightly playful. Age-appropriate celebration. "You did it! 🌟" Not "Task marked complete."
- Rue speaks the same way to both — warm, direct, slightly wise. Never robotic.

### Brand Parallel Track (not a development phase — run concurrently)
- [ ] USPTO trademark search for "Pyrch" in Class 42 (SaaS) and Class 41 (education/entertainment for children) — **hard blocker on logo commission and LLC formation**
- [ ] Brand voice guide — write before Phase 2 copy work begins
- [ ] Commission Pyrch wordmark (after trademark clears): incorporate subtle perching visual (Rue owl silhouette or lettermark suggesting wings/branch)
- [ ] AI transparency landing page section: what data is stored, whether child photos train models, who reviews AI decisions, how parents override — answer preemptively, the pyrch.ai domain primes these questions

---

## Tech Stack (V2)

| Layer | Decision | Change from V1 |
|---|---|---|
| Framework | Rails 7.2 (or latest 7.x stable) | Minor version bump from 7.1 |
| Database | PostgreSQL | Same |
| Asset pipeline | Propshaft | Replaces Sprockets — lighter, more modern |
| Frontend | Tailwind CSS + Hotwire (Turbo + Stimulus) | Same |
| Auth | Devise (adults only) + custom PIN session (children) | Simplified vs ChoreQuest's dual-model Devise |
| Authorization | **Pundit** | New — replaces scattered `authenticate_parent!` guards |
| AI | Anthropic Claude API (via `anthropic` gem) | Same |
| Background jobs | **GoodJob** (PostgreSQL-backed) | New — replaces inline/async, no Redis required |
| File storage | ActiveStorage | Same |
| Deployment | Render.com + PostgreSQL | Same |
| Push notifications | `webpush` gem + VAPID keys | New |
| Pagination | `pagy` | New — ChoreQuest had none |

### Key Gem List (Phase 1)
```ruby
gem "devise"
gem "devise_invitable"   # child → adult promotion invite flow
gem "pundit"
gem "good_job"
gem "anthropic"
gem "image_processing"   # ActiveStorage variants
gem "discard"            # soft deletes for User and Household
gem "heroicons"
gem "pagy"
```

---

## Core Architecture: The Household

### The Fundamental Shift

Everything in Pyrch belongs to a **Household**. This is the core departure from ChoreQuest, where `Parent` was the root owner. In V2:

- **`Household`** replaces `Parent` as the security boundary
- **Single `User` model** replaces the separate `Parent` and `Child` models
- **`HouseholdMembership`** is the join table with role enum

### Data Model

```
AdminUser                         ← PLATFORM OPERATOR ONLY (the founder/developer)
  email: string (NOT NULL, unique)
  encrypted_password: string
  # Devise-managed. Has no household. Accesses /admin/** routes only.
  # Has NOTHING to do with household management.

User                              ← ADULT HOUSEHOLD MEMBERS ONLY
  email: string (NOT NULL, unique)
  encrypted_password: string
  display_name: string (NOT NULL)
  avatar_color: string
  discarded_at: datetime          ← soft delete via discard gem
  # Devise-managed. Belongs to one or more households via HouseholdMembership.
  # "User" in code always means an adult. Never a child. Never a superadmin.

Child                             ← CHILD HOUSEHOLD MEMBERS ONLY
  household_id: references (NOT NULL) — primary household; multi-household via ChildHouseholdMembership (Phase 6+)
  display_name: string (NOT NULL)
  pin_code_digest: string (NOT NULL) — bcrypt-digested PIN, never plaintext
  public_token: string (NOT NULL, unique, indexed) — UUID for child-facing URLs
  birthday: date
  avatar_color: string
  discarded_at: datetime          ← soft delete via discard gem
  promoted_user_id: references users (nullable) — set when child is promoted to adult User

Household
  name: string (NOT NULL)
  slug: string (NOT NULL, unique, indexed) — UUID-backed, not human-guessable
  plan_tier: string (NOT NULL, default: 'trial') — enum: 'free', 'trial', 'family'
  discarded_at: datetime
  # Security boundary. All User and Child data scoped through current_household.

HouseholdMembership               ← JOINS Users TO Households (adults only)
  belongs_to :household
  belongs_to :user                ← User model only — Children belong_to Household directly
  role: enum [household_admin, adult_member]
  status: enum [active, invited, suspended]
  display_order: integer
  # ROLE RULES:
  # household_admin — full access including billing/settings/member management
  # adult_member    — full content access, no billing or role management
  # Multiple household_admin members allowed. Minimum 1 required (enforced on demote).
  # Destructive actions (cancel subscription, delete household) require email confirmation
  #   even for household_admin — prevents accidental or hostile destruction.
  # All role changes are logged (who changed what, when).
```

### Household URL Strategy
Path-based household slug: all routes inside a household live under `/h/:household_slug/`. The profile picker lives at `/h/:slug`. Child public URLs are `/h/:slug/u/:public_token`.

- Household slug is UUID-backed (not the household name) to prevent enumeration
- On first visit to `/h/:slug`, the profile picker is always shown
- A "Return to [Household Name]" link persists in localStorage so bookmarked devices return to the right household automatically

### Child → Adult Promotion
A `household_admin` can promote any `Child` to an adult `User` in the household. This is explicit, intentional, and irreversible (though the resulting `User` can be removed from the household later).

**What happens on promotion:**
1. Household admin initiates from the child's profile in Settings
2. System prompts for the child's email address (required for Devise)
3. A `devise_invitable` invitation email is sent to that address
4. Child accepts the invitation and sets a password — this creates a new `User` record
5. A `HouseholdMembership` is created for the new `User` with role `adult_member`
6. The `Child` record gets `promoted_user_id` set to the new `User#id`
7. All historical data (token transactions, chore assignments, chore attempts) is migrated from `child_id` → `user_id` via a background job (`PromoteChildToUserJob`)
8. The `Child` record is soft-deleted (`discarded_at = Time.current`)
9. The PIN session for that `public_token` is invalidated; the person now logs in via Devise

**Implementation notes:**
- `PromoteChildToUserJob` runs after the invite is accepted (Devise callback), not at initiation — the child must accept before data migrates
- The job touches: `TokenTransaction`, `ChoreAssignment`, `ChoreAttempt` — update `child_id` FK to new `user_id` FK (or add a `user_id` column to these tables alongside `child_id` from Phase 1 to make this migration additive, not destructive)
- Historical chore data migrated to the `User` record is visible in their profile history
- The promoted person starts as `adult_member` — the household admin can later promote them to `household_admin` if appropriate

### Key Architectural Rules (enforced in all phases)

1. **Three separate models, never conflated** — `AdminUser` (platform), `User` (adult household member), `Child` (child household member). See the CRITICAL TERMINOLOGY section at the top of this document.
2. **Household is the security boundary** — all queries chain through `current_household`; no unscoped model finders in controllers, ever
3. **`User` in code = adult** — if a query, method, or variable is named `user`, it refers to a `User` model instance (adult). Never a `Child`. Never an `AdminUser`.
4. **Adults (`User`) authenticate via Devise** — `authenticate_user!`, `current_user`. Never route a `Child` through Devise.
5. **Children (`Child`) authenticate via PIN + `public_token`** — custom `ChildSessionsController`; session key: `session[:child_public_token]`; never store `child.id` (integer) in the session
6. **`AdminUser` authenticates via separate Devise installation** — separate `devise_for :admin_users` route scope; `current_admin_user` helper; no `AdminUser` ever appears in household-scoped queries
7. **No raw database integer IDs in user-facing URLs, forms, or sessions** — ever, for any model
8. **Pundit everywhere for `User` auth** — `verify_authorized` and `verify_policy_scoped` enforced at `ApplicationController` level; `Admin::ApplicationController` has its own Pundit scope for `AdminUser`
9. **Multiple household admins, minimum 1** — `HouseholdMembership` enforces at least one `household_admin` per household; demoting the last admin raises a `HouseholdAdminRequiredError`; all role changes are logged

### Multi-household Children (Architecture Day 1, UI Deferred)
A `User` (child) can have `HouseholdMembership` records in multiple households — the data model allows it from day one. Do not add a unique constraint on `(user_id)` in `household_memberships`. The multi-household UI (blended family management, separate token balances per household) is deferred to Phase 6+.

---

## Security Architecture (By-Design Fixes from ChoreQuest)

These are not patches — they are architectural patterns that make the entire class of ChoreQuest bugs impossible to introduce.

### Pattern 1: Authentication at the Class Level, Always
Every controller that touches authenticated resources calls `before_action :authenticate_user!` at the top of the class. Public controllers (profile picker, child public view) explicitly inherit from `PublicController` which opts out. No exceptions. Code review gate: if a controller inherits from `ApplicationController` with no class-level auth, it fails review.

### Pattern 2: Ownership Through Association Chains
No controller ever calls a model class method directly for user-owned data:
```ruby
# CORRECT — ownership is implicit in the chain
child = current_household.children.find(params[:user_id])
child.token_transactions.create!(amount: params[:amount])

# WRONG — never do this
TokenTransaction.create!(token_transaction_params)
```
A `user_id` that doesn't belong to `current_household` raises `ActiveRecord::RecordNotFound` (rescued to 404) before any write happens.

### Pattern 3: Play Gate — One Method, One Location
The play gate lives on `HouseholdMembership` (or `PlayGateService`):
```ruby
def eligible_to_play?(date: Date.current)
  assignments = chore_assignments.where(scheduled_on: date)
  return false if assignments.none?           # must have at least one assignment today
  assignments.where.not(approved: true).none? # all must be approved
end
```
Every controller and view that checks eligibility calls this exact method. It is tested with specs covering: no assignments → false, completed but not approved → false, all approved → true, mixed → false.

### Pattern 4: Confetti — Event-Specific, Not Notice-Based
Confetti is triggered only by a specific Turbo Stream event (`<turbo-stream action="replace" target="confetti-trigger">`) emitted by the server on genuine chore approval. It never fires on flash notices. The confetti Stimulus controller listens for this stream event only.

### Pattern 5: GameSession ended_at → stopped_at
`GameSession#stopped_at` starts `nil` on creation. It is set in exactly two places: when the heartbeat detects tokens exhausted, and when the explicit `stop_session!` action is called. The `before_create` callback never touches `stopped_at`. Scope: `GameSession.active → where(stopped_at: nil)`.

### Pattern 6: No Stale Session 500s
The layout never calls any database finder directly. All layout-level data comes from `current_user` (nil-safe Devise helper). If `current_user` returns nil, Devise redirects to sign-in — no 500 possible. Any controller that sets session variables for child auth must use `find_by` (not `find`) and handle nil explicitly.

### Pattern 7: PIN Never Stored Plaintext
Child PINs are stored as bcrypt digests (`pin_code_digest`). The login check runs `BCrypt::Password.new(user.pin_code_digest) == params[:pin]`. Never store the PIN in plaintext, never log it, never return it in any API response.

---

## Profile Picker (The Household Entry Point)

The profile picker is the home screen for Pyrch. It replaces the awkward split between Devise login and the public child URL. Every household has a dedicated picker at `/h/:household_slug`.

### How It Works
- Full-screen dark background, all household members shown as large circular avatars
- **Child flow:** tap avatar → large PIN keypad modal (NOT native keyboard — too small; 10 large number buttons + backspace) → correct PIN redirects to `/h/:slug/u/:public_token` (child public view)
- **Adult flow:** tap avatar → Devise email/password sign-in
- **Authenticated parent:** can tap any child avatar to preview the child's view without entering PIN (trust the parent's Devise session)

### LocalStorage Persistence
```javascript
// Stored after successful auth
{ profile_type: 'child', public_token: '...', name: 'Emma', household_slug: '...' }
// or
{ profile_type: 'adult', user_id: '...', name: 'Alice', household_slug: '...' }
```
On return visit: show "Continue as Emma" with one large tap target + small "Switch Profile" link. "Switch Profile" becomes the replacement for the dead token balance slot in the child bottom nav.

### Stale Token Recovery
When localStorage has a `public_token` that no longer resolves (parent regenerated it): the profile picker shows "Your link changed — ask a parent" instead of a 500 or broken redirect.

### Token Verification Endpoint
The profile picker verifies the stored `public_token` on page load: `GET /h/:slug/verify_profile?token=X` returns 200 (valid) or 404 (stale). One cheap round-trip; prevents silent stale-token failures.

---

## Child Module Home Screen

The child-facing view is a **modular home screen**, not a flat chore list. Each module is a card the child taps into.

### Module Cards (in display order)
| Card | Pyrch Module | Phase |
|---|---|---|
| Chore Quest | Chores | Phase 2 (content), Phase 1 (card shell) |
| Token Tracker | Token economy | Phase 1 |
| Game Hub | Games | Phase 3 |
| Homework | Homework Module | Phase 5 |
| Allowance | Allowance Module | Phase 6 |
| Rewards Store | Rewards Store | Phase 7 |

### How It Works
- Phase 1 ships with all card shells visible; inactive modules show as "Coming soon" or are hidden based on `HouseholdModuleConfig`
- Each card is a Turbo Frame — cards refresh independently on poll
- `HouseholdModuleConfig` controls which modules are enabled per household
- Parent configures module visibility in Settings

### Why This Matters
Building a flat chore list in Phase 1 and retrofitting modules later IS the ChoreQuest anti-pattern. The module card architecture must be designed from Phase 1 even if only 1–2 cards have live content.

---

## Module System

```
HouseholdModuleConfig
  belongs_to :household
  module_key: string (NOT NULL) — 'chores', 'games', 'homework', 'allowance', 'rewards', 'calendar', 'school'
  enabled: boolean (NOT NULL, default: true)
  display_order: integer (NOT NULL, default: 0)
  settings: jsonb — module-specific config
  Unique constraint: (household_id, module_key)
```

Usage:
```ruby
HouseholdModuleConfig.enabled_for(current_household, :games) # → true/false
```

---

## Rue-First Development Rule (Unchanged from V1, Reinforced)

**Non-negotiable convention:** Every new feature ships with a corresponding Rue action in the same PR. A PR without a Rue action is not mergeable.

### V2 Rue Tool Architecture

Tools are organized as service objects, not controller private methods:

```
app/services/rue/
  base_tool.rb             # abstract: name, description, input_schema, call(input, household)
  tool_registry.rb         # Registry.all → array, Registry.find(name).call(input, household)
  tools/
    household_tools.rb     # list_members, get_today_summary
    chore_tools.rb         # list_chores, assign_chore, list_unassigned_chores
    approval_tools.rb      # list_pending, approve_attempt, reject_attempt, bulk_approve
    token_tools.rb         # grant_tokens, get_balance
    feedback_tools.rb      # log_feature_request (capability boundary fallback)
  client.rb                # the agentic loop; calls ToolRegistry
  system_prompt.rb         # builds system prompt from current household context
controllers/
  rue_controller.rb        # thin: load RueConversation, call Rue::Client, render reply
```

### Key Rue Implementation Rules (from ChoreQuest experience)
- `response.stop_reason == :tool_use` and `b.type == :tool_use` — **symbols, not strings** (Anthropic gem v1.23+)
- Serialized history stored to DB uses string keys; live gem response objects use symbol comparisons
- Add max-iterations guard to the agentic loop (`raise Rue::LoopError if iterations > 10`)
- All tool `call` methods rescue `StandardError` and return error strings — Claude reports failures conversationally
- Tool scoping: tools available to Rue are scoped to the currently active module context (prevents tool list bloat as modules grow)

### RueConversation Model (DB-backed, not session)
```
RueConversation
  belongs_to :household
  messages: jsonb (array of message hashes)
  truncate_to_last_n(20) method
```
Session-based history hits Rails session size limits. DB-backed history scales.

### Rue Capability Boundary Fallback
When Rue cannot do something: "My boss hasn't taught me how to do that yet! Want to let him know so he can add it to my skills?"
If parent says yes → `log_feature_request` tool creates a `FeedbackPost` record (Phase 4).
Rue confirms: "Done! He'll see it — the most-asked things get built first."

---

## Pricing Model

### Free Tier (forever free)
- 2 children max
- 10 active assignments at a time across all children
- 1 game (Pong / starter game only)
- 3 Rue interactions per day
- Manual photo approval only (no AI verification)
- No recurring schedules
- No Homework, Allowance, or Rewards modules
- All core features (chore tracking, token ledger, profiles) fully functional

### Pyrch Family — $12/month or $96/year (save 33%)
- Unlimited children
- Unlimited assignments
- All games
- Unlimited Rue interactions
- AI photo verification (Rue reviews photos automatically)
- Recurring schedules
- All current and future modules (Homework, Allowance, Rewards Store, Calendar, School Hub)
- Co-parent invite
- Push notifications
- Weekly digest email
- Chore analytics dashboard

### Free Trial
- 14-day free trial of Family plan on signup — **no credit card required**
- On day 12: "Rue goes back to basics in 2 days" email
- On expiry: **silent downgrade** to free tier limits (never hard-lock — children must still see their chore list or the family churns immediately)

### Four Upgrade Triggers (friction moments that prompt upgrade)
1. **3rd child creation** — intercept before save: "Your household is full on the free plan. Upgrade to Pyrch Family to add unlimited children and unlock Rue's full capabilities."
2. **First manual photo approval** — one-time interstitial: "You just did Rue's job. On Pyrch Family, Rue reviews every photo automatically — you only see the ones that need a second opinion."
3. **Recurring schedule toggle** — visible but locked (gray + lock icon) on free tier; tap shows: "Recurring schedules are a Pyrch Family feature." with Upgrade link
4. **4th Rue message in a day** — Rue responds in character: "I would love to help with that, but I've hit my limit for today on the free plan. Ask my boss to upgrade and I can work all day, every day!" then shows the upgrade link

### Implementation
- `plan_tier` enum on `Household`: `free`, `trial`, `family`
- All plan limit checks go through a central `PlanPolicy` service object — never scattered across controllers
- `FeatureFlagService.enabled?` defers to `PlanPolicy` for plan-gated features
- Stripe integration in Phase 4; `plan_tier` column added in Phase 1 (default: `trial` during 14-day window, then `free`)

---

## Standing Rules (Enforced in All Phases)

1. **Mobile-first, always.** Every view is designed for the smallest screen first. Desktop is an enhancement. Any PR that introduces a desktop-only layout pattern is rejected.
2. **Minimum 44×44px tap targets** on all interactive elements.
3. **Bottom tab navigation** for both parent and child roles — no hamburger menus.
4. **No integer database IDs** in any user-facing URL, form field, or session variable.
5. **Every controller authenticates at the class level** — no per-action auth guards.
6. **Every query chains through `current_household`** — no unscoped model finders.
7. **Every feature ships with a Rue action** — no exceptions, same PR.
8. **Security audit** at the end of every phase before starting the next.

---

## Development Phases

---

### Phase 1 — Core Foundation + Chore Loop MVP

**Goal:** A family can sign up, add children, assign chores, kids submit photo proof, Rue analyzes it, parent approves, kid earns tokens. Everything is mobile-first and secure. The profile picker is the entry point.

**Deliverables:**

#### Models & Auth
- [ ] `AdminUser` model — Devise (separate installation at `/admin`); no household association; used only for platform superadmin access
- [ ] `User` model — Devise + `devise_invitable`; `discarded_at` soft delete; adults only
- [ ] `Child` model — `household_id`, `display_name`, `pin_code_digest`, `public_token` (UUID, indexed), `birthday`, `avatar_color`, `discarded_at`, `promoted_user_id (nullable)`; NOT Devise
- [ ] `Household` model — `name`, `slug` (UUID-backed, unique, indexed), `plan_tier` (default: `trial`), `discarded_at`
- [ ] `HouseholdMembership` — joins `User` to `Household`; roles: `household_admin`, `adult_member`; status: `active`, `invited`, `suspended`; `display_order`; Children do NOT have a `HouseholdMembership` — they `belongs_to :household` directly
- [ ] `HouseholdMembership` constraint: cannot demote last `household_admin` (model-level validation); all role changes logged
- [ ] Household creation flow: sign up → create `User` → create `Household` → `HouseholdMembership` with `household_admin` role → 14-day trial starts → add first child
- [ ] `HouseholdModuleConfig` model (stub — enables/disables modules per household)
- [ ] `PlanPolicy` service object: all plan limit checks go here — `PlanPolicy.new(household).can_add_child?`, `PlanPolicy.new(household).ai_analysis_enabled?`, etc.

#### Auth & Security
- [ ] Pundit installed; `verify_authorized` + `verify_policy_scoped` enforced at `ApplicationController` for `User` auth; `Admin::ApplicationController` uses separate Pundit scope for `AdminUser`
- [ ] `Child` auth: custom `ChildSessionsController` — looks up `Child` by `public_token` (UUID), verifies PIN digest; session key: `session[:child_public_token]`; never stores `child.id` integer
- [ ] `User` auth: standard Devise (sign up, sign in, password reset, invite); children never reach these routes
- [ ] `AdminUser` auth: separate Devise scope at `/admin/sign_in`; `authenticate_admin_user!` before_action on all `Admin::` controllers
- [ ] GoodJob installed and configured; deploy as separate worker process on Render.com

#### Profile Picker
- [ ] `/h/:household_slug` route renders the profile picker (unauthenticated)
- [ ] Large circular avatars for all household members, dark background
- [ ] Child flow: tap → custom PIN keypad modal (10 large buttons + backspace, not native keyboard)
- [ ] Adult flow: tap → Devise sign-in
- [ ] Authenticated parent can tap any child avatar to preview without PIN
- [ ] localStorage persistence (`profile_type`, `public_token`, `name`, `household_slug`)
- [ ] Stale token recovery: `GET /h/:slug/verify_profile?token=X` → 200 or 404 with graceful "Your link changed — ask a parent" message

#### Chore Module (Phase 1 Scope)

**Note: Chores are for the whole household — Users (adults) AND Children can be assigned chores.** Pyrch is a household management app. `ChoreAssignment` uses a polymorphic `assignee` (either a `User` or a `Child`).

- Adults (`User`) assigned chores see them in a "My Tasks Today" section on their dashboard (not the child module home screen)
- Token earning for adult chores is optional per chore (some households opt adults into the token economy; others use it purely as task tracking)
- The play gate only applies to `Child` members — adult chore completion never gates any feature
- Approval flow for adult chores: self-mark done; no photo required by default; no AI analysis

- [ ] `Chore` model: `name`, `description`, `definition_of_done`, `token_value`, `household_id`
- [ ] `Chore` model: `has_many :chore_tasks` stub (optional association, starts empty; Phase 2 populates it)
- [ ] `ChoreAssignment`: `chore_id`, `household_id`, `scheduled_on`, `require_photo`, `approved`; polymorphic `assignee` (type + id — either `User` or `Child`); also store `user_id (nullable)` and `child_id (nullable)` as explicit FKs (easier to query than pure polymorphic); unique constraint on `(assignee_type, assignee_id, chore_id, scheduled_on)`
- [ ] `ChoreAttempt`: `chore_assignment_id`, `status` enum (`pending_ai`, `pending_parent`, `approved`, `rejected`, `needs_review`), `ai_message`, `parent_note`, `submitted_note`; `has_one_attached :photo`
- [ ] AI photo analysis: `AnalyzeChorePhotoJob` (GoodJob) calls Anthropic API; "inconclusive" → `needs_review` (escalates to parent, not auto-reject)
- [ ] Play gate: `eligible_to_play?` method on `HouseholdMembership`; correct logic from day one

#### Token Economy
- [ ] `TokenTransaction`: `user_id`, `household_id`, `amount` (integer), `kind` enum (`earned`, `spent`, `granted`, `refunded`), `description`
- [ ] Token balance = sum of `amount` from `TokenTransaction` records (no balance column — append-only ledger)

#### Child Module Home Screen
- [ ] `/h/:slug/u/:public_token` route renders child's module home screen
- [ ] Module card grid: Chore Quest card (active), Token Tracker card (active), Game Hub card (visible but inactive — Phase 3)
- [ ] All dynamic content (chore status, token balance, play gate) inside `<turbo-frame>` blocks
- [ ] Adaptive poll interval: 3–5s while a pending attempt exists, 15s otherwise
- [ ] Photo preview before submission (JavaScript camera API — child can retake before submitting)
- [ ] Age-appropriate status language: "Being checked... 👀" not "Awaiting review", "Try again! 🔄" not "Rejected"
- [ ] Celebration animation (confetti + "+N tokens!") triggered by `chore-approved` Turbo Stream event only — never by flash notice

#### Parent Dashboard
- [ ] Today's pending approvals queue (photo, child name, chore name, Approve/Reject)
- [ ] "Today at a Glance" panel: per-child completion status
- [ ] Mobile card layout on small screens (not a wide table)
- [ ] Manual chore assignment form (no drag-and-drop yet — Phase 2)

#### Navigation
- [ ] Parent: 4-tab bottom navigation (Today with pending badge, Kids, Schedule, More)
- [ ] Parent: slim top bar (logo only on mobile; full nav on md+)
- [ ] Child: 3-tab bottom navigation (Chores, Tokens, Switch Profile)
- [ ] Active state styling on all nav items
- [ ] Footer hidden on mobile (`hidden md:block`)
- [ ] Shake animation + "Finish your chores first!" message when locked Play button is tapped

#### Rue (Phase 1 — Informational Only)
- [ ] Rue floating chat button in parent layout
- [ ] `RueConversation` model (DB-backed, jsonb `messages`, `truncate_to_last_n(20)`)
- [ ] Rue service object layer: `Rue::Client`, `Rue::ToolRegistry`, `Rue::BaseTool`
- [ ] Phase 1 Rue tools (read-only): `list_children`, `get_token_balance`, `get_today_summary`, `list_pending_approvals`, `log_feature_request` (capability boundary fallback — logs to simple text stub until FeedbackPost exists in Phase 4)
- [ ] Rue capability boundary fallback behavior implemented

#### Security Audit (end of Phase 1)
- [ ] Every controller has class-level `authenticate_user!` or inherits from `PublicController`
- [ ] Every query chains through `current_household`
- [ ] No integer IDs in user-facing URLs or forms
- [ ] Pundit `verify_authorized`/`verify_policy_scoped` passing for all actions
- [ ] PIN stored as bcrypt digest, never plaintext

---

### Phase 2 — Chore Expansion + Co-parents + PWA + Analytics

**Goal:** The app is good enough to invite real families. Analytics, scheduling, and PWA install make it feel like a real product.

**Deliverables:**

#### Chore Sub-tasks (full implementation, Phase 1 stub becomes real)
- [ ] `ChoreTask`: `chore_id`, `title`, `description`, `display_order`; `has_one_attached :model_photo`
- [ ] `ChoreAttempt` gains `chore_task_id` (nullable FK — nil = whole-chore attempt, backward compatible)
- [ ] `model_photo_snapshot` on `ChoreAttempt` (ActiveStorage blob ID at submission time — parent may update model photo later)
- [ ] Child submission flow: when a chore has tasks, child submits one photo per task
- [ ] `ChoreAssignment#complete?`: all tasks approved (not just a single attempt status)
- [ ] AI prompt updated to pass model photo URL alongside child's photo for task-level comparison
- [ ] Parent task management: add tasks to a chore, upload model photos per task

#### Co-parent Invite Flow
- [ ] `HouseholdInvitation`: `household_id`, `invited_by_id`, `email`, `token` (SecureRandom.urlsafe_base64, unique), `role`, `expires_at` (7 days), `accepted_at`; unique constraint on `(household_id, email)`
- [ ] Invite email via ActionMailer
- [ ] Accept flow: validate token, not expired, create `HouseholdMembership`
- [ ] Co-parent has same access as owner within household scope; owner-only actions gated by Pundit `HouseholdPolicy`

#### Drag-and-Drop Scheduler (Desktop)
- [ ] Calendar view with drag-and-drop chore assignment (port from ChoreQuest)
- [ ] List/agenda view as toggle alternative (better for mobile reading)
- [ ] Completion status chips: color-coded by status (approved / pending / rejected)
- [ ] "+N more" overflow indicator on month view day cells when chores clip
- [ ] "Repeat weekly" checkbox for recurring assignments
- [ ] Per-assignment AI analysis toggle (some chores don't need photo review)
- [ ] Mobile scheduling UX: dedicated bottom sheet or mobile flow (do NOT make desktop drag-and-drop work on touch)

#### Chore Analytics Dashboard
- [ ] Completion rate per chore (required before Rue can make intelligent suggestions)
- [ ] Per-child engagement trends
- [ ] Overdue/skipped pattern detection
- [ ] AI suggestions: "Emma hasn't done Clean Room in two weeks — assign it?" (Rue informational)
- [ ] Data is captured in Phase 1 (timestamps on ChoreAssignment/ChoreAttempt); Phase 2 builds the UI and query layer

#### Rue Write-Action Service Layer
- [ ] Rue write tools: `assign_chore`, `approve_attempt`, `reject_attempt`, `grant_tokens`, `bulk_approve`
- [ ] `RueAction` audit log: every write action Rue performs is logged (action name, parameters, timestamp, which user triggered it)
- [ ] Parents can see "Rue assigned Clean Room to Emma on Monday" in a Rue history view

#### PWA
- [ ] `public/manifest.webmanifest` with app name, icons, display mode, theme color
- [ ] Service worker (`public/sw.js`) for app shell caching (layout, CSS, JS only — no dynamic data)
- [ ] iOS Safari: detect iOS + not-standalone → show one-time "Tap Share → Add to Home Screen" banner; dismiss to localStorage
- [ ] Android/Chrome: intercept `beforeinstallprompt` → show "Install App" button in nav or banner
- [ ] `safe-area-inset-top` padding on child public view for iOS PWA mode

#### Feature Flags
- [ ] `beta_features` column on `HouseholdMembership` (jsonb) — simple flag storage for Phase 2; escalate to proper table in Phase 4
- [ ] Beta badge on flagged features in UI

#### Profile Picker Polish
- [ ] LocalStorage "Continue as Emma" fast path (page load shows "Continue as [name]" with one tap + small "Switch" link)
- [ ] Token transaction filter pills + color-coded ledger (green = earned, red = spent)
- [ ] Real-time verdict updates via Turbo Streams (replace AI result polling with push)

#### Settings Page
- [ ] Profile card: display name, avatar color picker
- [ ] Email + password change
- [ ] Account deletion danger zone
- [ ] Child management: add/remove children, reset PINs, set display order
- [ ] PIN codes hidden behind "Show" toggle (never plaintext in the default view)
- [ ] Module configuration: enable/disable modules per household

#### Rue (Phase 2 additions)
- [ ] Rue can now assign chores and approve attempts via conversation (write-action service layer)
- [ ] Rue's chore analytics tools: `get_chore_analytics`, `list_overdue_assignments`, `suggest_chore`

#### Security Audit (end of Phase 2)

---

### Phase 3 — Games Module

**Goal:** Kids can earn game time and spend tokens. The full chore → token → game loop is complete.

**Deliverables:**

- [ ] `Game`: `household_id`, `name`, `slug`, `description`, `url` (path to static HTML file)
- [ ] `GameSession`: `user_id`, `game_id`, `household_id`, `duration_minutes`, `started_at`, `stopped_at` (nil at create), `stopped_early`; row-level locking on token deductions (`user.with_lock`)
- [ ] `GameScore`: `user_id`, `game_id`, `score`, `session_id` — `session_id` required, verify caller owns it; never accept raw `user_id`/`game_id` from untrusted caller
- [ ] Heartbeat endpoint: `skip_before_action :verify_authenticity_token, only: [:heartbeat, :stop]`; verify session ownership via `current_household` even with CSRF skipped
- [ ] Enforce server-side minimum `duration_minutes: [params[:duration_minutes].to_i, 1].max`
- [ ] Game Hub module card on child home screen becomes active
- [ ] Play gate powered by `eligible_to_play?` — same method from Phase 1
- [ ] Play button and token balance inside `<turbo-frame>` so polling updates them
- [ ] Berry Hunt + additional games in `public/games/`
- [ ] Parent: game library management (enable/disable games per household)
- [ ] Rue tools: `check_play_eligibility`, `list_available_games`, `get_game_session_status`
- [ ] Security audit

---

### Phase 4 — Monetization + Marketing + Conversational Rue

**Goal:** The app has a paywall, a public face, and Rue can take actions by conversation.

**Deliverables:**

#### Stripe Subscription
- [ ] `Subscription` model: `household_id`, `plan` (`free`, `family`), `stripe_subscription_id` (nullable), `current_period_end`
- [ ] $10/month `family` plan; free plan: 1 child, basic chore tracking, no AI analysis, no games
- [ ] Stripe webhook handling (subscription created/updated/cancelled)
- [ ] Feature gates: AI photo analysis and Games Module gated behind `family` plan
- [ ] `Household#plan` helper returns `:free` or `:family`

#### Marketing Site
- [ ] Public landing page: "Your kids earn their screen time. No more nagging." headline
- [ ] Looping demo video (chore submission → approval → game unlock flow)
- [ ] "Start Free — No Credit Card" CTA
- [ ] "Why no app store?" section: frame PWA-only as a cost-saving trust signal
- [ ] AI transparency section: what's stored, who reviews AI decisions, how parents override
- [ ] Pronunciation guide ("Pyrch, rhymes with perch") in footer

#### Conversational Rue (AI-First Interface)
- [ ] Rue can execute all write actions via conversation (calls Phase 2 RueAction service layer)
- [ ] Parents can type: "assign Clean Room to Emma every Monday for 4 weeks"
- [ ] Rue interprets date ranges, recurring patterns, child names (fuzzy match by display_name)
- [ ] Tool scoping: Rue presents tools relevant to the current module context only

#### Parent Feedback + Feature Voting Board
- [ ] `FeedbackPost`: `household_id`, `title`, `description`, `source` (`user_submitted`, `rue_conversation`), `vote_count` (counter cache), `status` (`open`, `planned`, `shipped`), `public`
- [ ] `FeedbackVote`: `feedback_post_id`, `household_id`; unique on `(feedback_post_id, household_id)`
- [ ] Link from Settings page and More sheet in parent nav
- [ ] Rue capability boundary fallback now creates real `FeedbackPost` records (replaces Phase 1 stub)

#### Feature Flag Upgrade
- [ ] `FeatureFlag`: `key` (unique string), `description`, `enabled_globally`, `rollout_percentage`
- [ ] `HouseholdFeatureFlag`: `household_id`, `feature_flag_id`, `override` (`enabled`/`disabled`/nil)
- [ ] `FeatureFlagService.enabled?(:key, current_household)` — checks household override, then global, then rollout %
- [ ] Beta households see "Beta" badge on flagged features

#### Rue (Phase 4 additions)
- [ ] `suggest_reward`, `add_reward`, `list_feedback`, `log_feature_request` (now creates real `FeedbackPost`)
- [ ] Rue audit log visible to parents: "Rue assigned Clean Room to Emma on Monday"

#### Security Audit

---

### Phase 5 — Homework Module

**Goal:** Parents can track school assignments, kids earn tokens for completing homework.

**Deliverables:**

- [ ] `HomeworkTask`: `title`, `subject`, `due_date`, `points`, `user_id`, `household_id`, `completed_at`
- [ ] Completion tracking: token reward on completion (optional, configurable per task)
- [ ] Homework module card on child home screen
- [ ] Rue suggestions: study time, streak celebrations, upcoming due dates
- [ ] Rue tools: `add_homework_task`, `list_homework_due`, `mark_homework_done`, `get_homework_summary`
- [ ] Security audit

---

### Phase 6 — Allowance Module

**Goal:** Real money tracking alongside tokens.

**Deliverables:**

- [ ] `AllowanceRule`: `weekly_amount`, `pay_day`, `user_id`, `household_id`
- [ ] `RealMoneyTransaction`: `amount`, `kind` (`earned`, `spent`, `saved`), `description`, `user_id`, `household_id`
- [ ] Savings goal tracking with progress bar
- [ ] Rue tools: `get_allowance_balance`, `set_allowance_rule`, `log_money_transaction`, `get_savings_goal_progress`
- [ ] Security audit

---

### Phase 7 — Rewards Store + Family Calendar

**Goal:** Kids can redeem tokens for parent-defined rewards. Shared family calendar.

**Deliverables (Rewards Store):**
- [ ] `Reward`: `name`, `token_cost`, `household_id`, `has_one_attached :image`
- [ ] `RewardRedemption`: `user_id`, `reward_id`, `redeemed_at`, `approved_by_id` (optional)
- [ ] Parent approves redemptions
- [ ] Rue tools: `list_rewards`, `get_redemption_queue`, `approve_redemption`, `reject_redemption`, `add_reward`

**Deliverables (Family Calendar):**
- [ ] `Event`: `title`, `start_at`, `end_at`, `household_id`, `created_by_id`, `adult_only`, `recurring`
- [ ] Child-visible vs adult-only events
- [ ] Rue tools: `create_event`, `list_upcoming_events`, `delete_event`, `check_schedule_conflicts`
- [ ] Security audit

---

### Phase 8 — School Communications Hub

**Goal (POC first):** Validate email ingestion and Rue parsing before building the full module.

**POC scope:**
- [ ] ActionMailbox setup + Mailgun inbound routing to `/webhooks/inbound_email`
- [ ] `SchoolMessage`: `household_id`, `source` enum (`email`, `sms`, `manual`), `raw_content`, `parsed_summary`, `child_id` (nullable), `category` enum (`event`, `homework`, `permission_slip`, `absence_alert`, `newsletter`, `announcement`, `unknown`), `action_item`, `deadline`, `actioned`, `adult_only`
- [ ] `RueParseMessageJob`: calls Claude API, returns structured JSON; writes parsed fields back to `SchoolMessage`
- [ ] Basic inbox UI: unactioned items surfaced at top; filter by child and category
- [ ] Validate: is Rue's parsing reliable enough to be useful?

**Full module (only if POC validates):**
- [ ] Twilio SMS number per household
- [ ] `CalendarEventProposal` + `HomeworkProposal`: one-tap confirmation creates Event or HomeworkTask
- [ ] Child visibility controls (`adult_only` flag)
- [ ] Rue tools: `check_school_inbox`, `get_message_detail`, `action_message`, `confirm_calendar_proposal`, `confirm_homework_proposal`, `dismiss_proposal`
- [ ] Third-party integrations (ClassDojo, Remind, Google Classroom): deferred; schema accepts additional `source` enum values without migration
- [ ] Security audit: Mailgun/Twilio signature validation on all webhook endpoints

---

## Bootstrap Guide (Phase 1 Concrete Steps)

### Step 1: `rails new`
```bash
rails new pyrch \
  --database=postgresql \
  --asset-pipeline=propshaft \
  --javascript=importmap \
  --css=tailwind \
  --skip-test \
  --skip-action-mailbox \
  --skip-action-text
```
Then add `test/` directory structure manually with correct fixtures layout and Minitest pin (`~> 5.25`).

### Step 2: Add Gems
```ruby
# Gemfile
gem "devise"
gem "devise_invitable"   # child → adult promotion
gem "pundit"
gem "good_job"
gem "anthropic"
gem "image_processing"
gem "discard"            # soft deletes
gem "heroicons"
gem "pagy"
```

### Step 3: Run Generators (in dependency order)
```bash
# Auth — three separate models
rails generate devise:install
rails generate devise AdminUser          # platform superadmin — separate table, /admin routes
rails generate devise User               # adult household members
rails generate devise:invitable User     # for co-parent invite + child promotion flows

# Core domain — Household before memberships
rails generate model Household name:string slug:string plan_tier:string discarded_at:datetime

rails generate model HouseholdMembership \
  household:references user:references \
  role:string status:string display_order:integer

rails generate model Child \
  household:references \
  display_name:string pin_code_digest:string public_token:string \
  birthday:date avatar_color:string discarded_at:datetime \
  promoted_user_id:integer

# Add display_name, avatar_color, discarded_at to users via separate migration
# (never modify Devise-generated migration)

# Chore domain
rails generate model Chore \
  household:references name:string description:text \
  definition_of_done:text token_value:integer

rails generate model ChoreAssignment \
  chore:references household:references \
  assignee_type:string assignee_id:integer \
  user_id:integer child_id:integer \
  scheduled_on:date require_photo:boolean approved:boolean

rails generate model ChoreAttempt chore_assignment:references status:string ai_message:text parent_note:text submitted_note:text

rails generate model TokenTransaction user:references household:references amount:integer kind:string description:string

rails generate model HouseholdModuleConfig household:references module_name:string enabled:boolean display_order:integer

rails generate model RueConversation household:references messages:jsonb

rails generate good_job:install
rails generate pundit:install
```

### Step 4: Migration Order
1. `households`, `users` (Devise-generated) + add child columns migration
2. `household_memberships`
3. `chores`, `chore_assignments`, `chore_attempts`
4. `token_transactions`
5. `household_module_configs`
6. `rue_conversations`
7. GoodJob tables (independent)

Add foreign keys and NOT NULL constraints in each migration. Never defer to cleanup migrations.

### Step 5: Seeds Pattern
All seeds use `find_or_create_by!` — safe to re-run in production without wiping data.

---

## Lessons Learned from ChoreQuest (Carried Forward)

### Architecture
- **Household is the right security boundary** — not individual parents; co-parents see the same household data
- **Single User model** — the Parent/Child split caused friction everywhere; HouseholdMembership role is cleaner
- **Profile picker is Phase 1 infrastructure**, not a UX enhancement — it is the human expression of the Household model
- **Module card architecture from day one** — building a flat chore list and retrofitting modules repeats the ChoreQuest mistake
- **Plan unique constraints early** — ChoreAssignment's `(user_id, chore_id, scheduled_on)` must be in the migration, not discovered in tests
- **Turbo Frame `src` auto-fetches** — never put inline content AND `src` on the same turbo-frame
- **Links inside turbo-frames** need `data-turbo-frame="_top"` if they navigate away from the frame context

### AI Integration
- **AI photo analysis is a background job** — never run it in the request cycle
- **`definition_of_done` is essential** — the AI prompt must know what "done" looks like; this field is non-optional
- **"Inconclusive" escalates to human review** — not auto-reject; always give the parent the final say
- **Symbol comparisons** — `response.stop_reason == :tool_use` (symbols, not strings) in the Anthropic gem v1.23+

### Rue / Conversational AI (Hard-Won Lessons — 2026-03-04)

**Anthropic gem gotchas (gem v1.23+):**
- `response.stop_reason`, `b.type` — all enum values are **Ruby symbols** (`:end_turn`, `:tool_use`, `:text`), never strings
- `tool_call.input` — returns a hash with **symbol keys** (`:name`, `:pin_code`), not string keys; always call `.with_indifferent_access` before accessing with string keys, or use symbol keys throughout
- Error class is `Anthropic::Errors::APIError` (**all-caps API**), NOT `ApiError`; rescuing a nonexistent constant is silently ignored and the exception escapes; `InternalServerError` (529), `BadRequestError` (400), `RateLimitError` (429) are all subclasses of `APIError`; use `e.status` to get the HTTP status integer

**Never store conversation history in the Rails session cookie:**
- The encrypted session cookie has a hard 4KB limit; a single `create_chore` flow (5–6 turns, with verbose `definition_of_done` in tool_use blocks) easily exceeds it
- `session[key] = value` does **NOT** raise on assignment — the `CookieOverflow` exception fires in Rack middleware commit **after** the response is already sent; a `rescue ActionDispatch::Cookies::CookieOverflow` block around the assignment is structurally unreachable and provides false safety
- When the cookie write fails, the browser retains the old cookie; the next request loads stale history that can end with an `assistant: tool_use` block with no matching `tool_result` — Anthropic rejects this with a 400 `invalid_request_error`
- **Solution**: store history in the database from day one — a `jsonb` column on the User model or a dedicated `RueConversation` model; this is already captured as a resolved decision (`rue_conversations` table)

**Sanitize loaded history before every API call:**
- Check that history does not end with an `assistant` turn whose last content block is `type: tool_use` with no subsequent `user` turn containing `type: tool_result`; if detected, drop the orphaned assistant turn before sending to Anthropic

**Tool-use conversation sizing:**
- Each tool invocation adds **3 history entries**: user message + assistant turn (with tool_use block) + user turn (with tool_result); a 5-turn chore creation conversation generates 10–15 entries and ~3–5KB of raw JSON
- Truncate long string values in stored `tool_use` input blocks (e.g. `definition_of_done`) — Claude already acted on the full value in the current turn; the stored copy only needs to be recognizable for history context

**Agentic loop error handling pattern:**
```ruby
rescue Anthropic::Errors::APIError => e
  status = e.respond_to?(:status) ? e.status : nil
  if status == 529 || e.message.include?("overloaded")
    return "Rue is busy — try again in a moment"
  elsif status == 400 || e.message.include?("invalid_request")
    history.clear  # corrupt history; reset so next request starts clean
    return "I got confused — I've reset our conversation. Anything I created is still saved."
  end
  return "Unexpected error (#{status}). Please try again."
end
```

**System prompt should include live context:**
- Include today's assignments, children, and chores in the system prompt so Rue can answer status questions without a tool call
- Rebuild context on every request (it is the system prompt, not history) so it is always fresh

### Token / Game System
- **Heartbeat skips CSRF only for specific actions** — `skip_before_action :verify_authenticity_token, only: [:heartbeat, :stop]`; never skip globally
- **`stopped_at` is nil at creation** — only set when the session actually ends; `before_create` must NOT touch it
- **Row-level locking required** — `user.with_lock` on all token deductions to prevent race conditions
- **GameScores require `session_id`** — verify the caller owns the session; never accept raw `user_id`/`game_id`

### Security
- **Scope through the household, always** — `current_household.children.find(id)` raises 404 on mismatch
- **Two auth systems coexist** — adults: Devise; children: custom PIN session; never conflate them; keep separate session keys
- **Build records through associations** — `child.token_transactions.create!`, never `TokenTransaction.create!(params)`
- **`find_by` instead of `find`** when a record might legitimately not exist

### Testing
- Devise fixtures need `<% require 'bcrypt' %>` at top of `users.yml`
- Write auth gate tests first (unauthenticated → redirect), then ownership tests (wrong household → 404), then happy path
- Scaffold-generated tests are useless after authentication is added — delete immediately
- `assigns()` requires `rails-controller-testing` gem

### Mobile / PWA
- iOS never shows an automatic install prompt — must build a custom "Add to Home Screen" banner
- `safe-area-inset-top` needed for PWA mode on iOS (status bar overlap)
- Use `visibilitychange` event to trigger Turbo Frame refresh on tab refocus

### UI / UX
- **All dynamic content must be inside `<turbo-frame>`** — variables baked in at page load do not update on poll
- **`<details>/<summary>` for zero-JS toggles** — native HTML, no Stimulus needed for simple show/hide
- **Age-appropriate language everywhere on child-facing screens** — no system terms ("Awaiting review", "Rejected")
- **Play gate logic**: `where.not(approved: true)` — not `where(completed: false)` — children can game a `completed` flag

---

## Open Decisions

- [ ] **Free plan limits** — marketing strategist report pending; will be added before Phase 4 Stripe work
- [ ] **Pronunciation rollout** — marketing strategist report pending; will inform all copy and launch materials

## Resolved Decisions

- [x] **App name** — Pyrch (P-Y-R-C-H), domain pyrch.ai
- [x] **Mascot name** — Rue (small expressive owl)
- [x] **Trademark search** — completed 2026-03-03; cleared for Class 42 and Class 41
- [x] **Child age cutoff** — no automatic age transition; instead parents can manually promote a child User to a co_parent role (see Household Management section)
- [x] **Three-model architecture** — `AdminUser` (platform superadmin, separate table), `User` (adult household member), `Child` (child, separate table); "User" in code always means adult; see CRITICAL TERMINOLOGY section
- [x] **`HouseholdMembership` roles** — `household_admin` (was `owner`) and `adult_member` (was `co_parent`/`guardian`); multiple household admins allowed; minimum 1 required; destructive actions require email confirmation; all role changes logged
- [x] **Admin interface** — custom Rails `Admin::` namespace, `AdminUser` Devise model (separate from `User`); Pundit scope for AdminUser; no Administrate gem
- [x] **Soft deletes** — `discard` gem for `User`, `Child`, and `Household`; `discarded_at` timestamp column on all three
- [x] **Pricing model** — Free tier + $12/month Family plan ($96/year annual option); see Pricing section for full details
- [x] **Background jobs** — GoodJob (PostgreSQL-backed, no Redis, lower Render.com cost)
- [x] **Authorization** — Pundit (policy objects per model, `verify_authorized` enforced globally)
- [x] **Household URL strategy** — path-based slug: `/h/:household_slug` (no subdomain complexity)
- [x] **Games phase** — Phase 3 (separate from core chore loop; Phase 1 focuses on chore → token loop)
- [x] **Chore sub-tasks** — stub in Phase 1 (`has_many :chore_tasks, optional`), full implementation in Phase 2
- [x] **Multi-household children** — allowed at model layer from Phase 1 (no unique constraint on `user_id` in memberships); multi-household UI deferred to Phase 6+
- [x] **School Communications Hub** — POC-first (Phase 8); validate before full module investment
- [x] **Stripe timing** — Phase 4 (after Games Module proves full loop value); free tier through Phase 3
- [x] **Asset pipeline** — Propshaft (lighter than Sprockets for a new app with Importmap + Tailwind)
- [x] **Rue history storage** — DB-backed `RueConversation` model (jsonb), not Rails session
- [x] **Play gate logic** — `where.not(approved: true)` with at least one assignment today required; single method on HouseholdMembership; never duplicated in controllers

---

*Last updated: 2026-03-04. Synthesized from rails-architect, project-manager, pyrch-planner, and primary-developer agent reports. Rue lessons added after ChoreQuest implementation and debugging session.*
