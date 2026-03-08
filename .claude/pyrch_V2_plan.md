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

Pyrch is a **family operating system** — a modular platform built around the **Household** as the core unit. Parents and children in a household share a space where chores, rewards, learning, money, and schedules all connect. AI (via the raccoon mascot Rue) is woven throughout every module.

ChoreQuest proved the core loop works. Pyrch is the production app built right — secure, mobile-first, and AI-native from day one.

---

## Brand & Identity

### Name
**Pyrch** ✓ *decided* — phonetic respelling of "perch." The name ties to the mascot concept (Rue perches on your household) without being a dictionary word, making it trademarkable. (Original rationale referenced an owl; mascot is now a raccoon named Rue — the "perch" concept still holds.)

- Pronunciation guide "Pyrch (rhymes with perch)" must appear: near the logo on the marketing site, in the app footer, in all early audio content, and in any app store description
- Domain: **pyrch.ai**
- Never spell it "Prych" — the correct spelling has Y before R: **P-Y-R-C-H**

### Mascot: Rue
A small, expressive cartoon **raccoon**. Warm colors. Short, easy for kids to say. (Note: the mascot species changed from owl to raccoon during the UI POC phase. The name Rue and the "perch" etymology remain — Rue is simply a raccoon who perches on your household and keeps an eye on things.)

- All AI copy: "Ask Rue", "Rue suggests...", "Rue is thinking...", "Rue says...", "Rue approved Emma's chore"
- Never use "AI" where "Rue" can be substituted in user-facing copy
- Double meaning: Rue as a name is warm and distinctive; "to rue" means to reflect carefully

**Mascot implementation status: DEFERRED — use emoji placeholder**
- Custom SVG mascots at 100x100 viewBox did not land visually during POC work; engineering time on SVG illustration is not the right investment at this stage
- **Do NOT spend engineering time on SVG mascot assets until a professional designer is commissioned**
- Until a real mascot is designed, use the `🦝` emoji in all UI spots where Rue appears: nav logo area, Rue chat FAB button, Rue chat panel header
- The emoji placeholder keeps the UI wired and branded without blocking feature work

### Brand Voice Guide (required before Phase 2 copy is finalized)
- **For parents:** Plain declarative sentences. No jargon. Confident but not preachy. "Emma finished her chores. She earned 20 tokens." Not "Your child has successfully completed their assigned tasks."
- **For children:** Warm, encouraging, slightly playful. Age-appropriate celebration. "You did it! 🌟" Not "Task marked complete."
- Rue speaks the same way to both — warm, direct, slightly wise. Never robotic.

### Brand Parallel Track (not a development phase — run concurrently)
- [ ] USPTO trademark search for "Pyrch" in Class 42 (SaaS) and Class 41 (education/entertainment for children) — **hard blocker on logo commission and LLC formation**
- [ ] Brand voice guide — write before Phase 2 copy work begins
- [ ] Commission Pyrch wordmark (after trademark clears): incorporate subtle perching visual (Rue raccoon silhouette or lettermark suggesting a perch/branch); mascot is a raccoon, not an owl — brief the designer accordingly
- [ ] AI transparency landing page section: what data is stored, whether child photos train models, who reviews AI decisions, how parents override — answer preemptively, the pyrch.ai domain primes these questions

---

## Canonical UI Reference — POC 6

> **READ THIS BEFORE BUILDING ANY NEW SCREEN.**
>
> `public/pocs/poc-6-pyrch-v1.html` is the **approved design foundation** for the Pyrch V2 app. Open it in a browser before writing a single line of Rails view code. Every new view must match its layout and color system.

The POC is a standalone static HTML file served from the ChoreQuest repo at `/pocs/poc-6-pyrch-v1.html`. It is the output of the UI exploration phase and was approved as the design direction for Pyrch V2.

### What POC 6 Defines

| Design Element | Spec |
|---|---|
| Top bar | Logo (left) + hamburger icon (right); slim; mobile-only |
| Bottom tab nav | Today, Kids, Schedule, Modules, + Rue FAB (center) |
| Slide-out left nav | Triggered by hamburger; section groupings; full-height overlay |
| Rue chat panel | Bottom sheet; 75vh tall; slides up over content |
| Color: Navy | `#1E3A8A` — primary brand, nav bar, headings |
| Color: Amber | `#F59E0B` — accents, active states, Rue FAB |
| Color: Cream | `#F5F0E8` — page background |
| Color: Violet | `#7C3AED` — secondary accent, module badges |

### Rules for Pyrch V2 Rails Views

1. Every new view must match POC 6 aesthetics before any other design reference
2. Do not invent new colors outside the four-color palette above
3. Bottom tab nav is always present for authenticated users (both parent and child roles)
4. Rue FAB is the center item in the bottom nav — always amber, always the most prominent nav element
5. Top bar is logo-only on mobile; no text nav links in the top bar on small screens
6. Slide-out left nav uses the same section grouping pattern as POC 6

### Mascot Placeholder in POC 6

POC 6 uses the `🦝` emoji as a Rue placeholder in the nav logo, Rue FAB, and chat panel header. This is the correct pattern for all new views until a professional mascot is commissioned. Do not replace the emoji with an SVG illustration — that work is deferred.

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

### Pattern 8: API Rate Limiting & Usage Caps
Every external API call is guarded against over-consumption:
- **Anthropic (Claude)**: Rue interactions capped by `PlanPolicy` (3/day free, unlimited Family); `AnalyzeChorePhotoJob` includes a household-level daily cap (e.g., 50 analyses/day) to bound runaway costs; Rue Tutor sessions cap Claude calls per session
- **PIN brute-force protection**: lock a child's profile picker after 5 consecutive failed PIN attempts; notify household admin via push; household admin unlocks via Settings
- **All HTTP endpoints**: rate limiting via `Rack::Attack` configured in `config/initializers/rack_attack.rb`; protect sign-in, PIN attempts, and API endpoints
- **Stripe**: webhook endpoint is signature-verified; idempotency keys on all payment API calls
- **Mailgun / ActionMailbox**: inbound webhook is signature-verified; unknown senders silently dropped (never bounced — bouncing creates spam loops)
- **API manager agent** monitors per-service usage monthly and flags if costs deviate significantly from the established baseline

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

### Remember Me (Persistent Profile)
- **"Remember me on this device"** checkbox on the profile picker — when checked, the child's session persists across browser closes; the child is returned directly to their chore view on next visit without re-entering the PIN
- Implemented via a long-lived cookie (30 days) storing the `public_token`; token is still verified on each visit (stale → graceful "Your link changed — ask a parent" message)
- Adults (parents) use Devise's built-in "Remember me" checkbox on sign-in
- Per-device setting: each device stores its own remembered profile independently; clearing cookies removes it

### Passcode Configuration Per Member
- Household admin controls which members require a passcode via Settings → Members
- **Children**: PIN strongly recommended; household admin can disable for a specific child (e.g., a young child on a dedicated family tablet where the parent manages device access)
- **Adults**: Devise password always required; not disableable
- `HouseholdMembership` gains `require_pin_on_picker: boolean (default: true)` — when false, tapping the avatar on the profile picker bypasses the PIN step and goes directly to that member's home view; household admin configures this per member
- App always recommends enabling PINs for parent accounts in the Settings UI — if children get to the parent picker profile and there is no PIN, they could access parent settings

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
9. **Design for flexibility.** When choosing between two implementation approaches, ask: "Which positions us better for future enhancements?" If both serve current needs equally, prefer the more extensible one. Never over-engineer for hypothetical requirements, but never paint into a corner either.
10. **Primary developer and UX designer pair on every new user-facing view.** No solo UI work on core features without UX sign-off. Walk through one screen at a time. This prevents the "unstyled scaffold" pattern from repeating.

---

## Development Phases

---

### Phase 0 — Environment & Infrastructure Setup

**Goal:** Before writing a single line of Pyrch code, all environments are configured, all API keys are secured, all agents are briefed, and the developer has a clear Git workflow that prevents losing work.

**Why Phase 0:** ChoreQuest was built without a proper environment strategy. Secrets were managed ad-hoc, dev/prod were blurred, and recovering from broken states was manual. Pyrch fixes this before line one.

#### Git & GitHub Strategy
- [ ] Two GitHub repositories: `pyrch-dev` (sandbox — break freely) and `pyrch` (production — clean main branch only)
- [ ] `pyrch-dev`: local dev + experimentation; CI optional; branch freely; use to recover from broken state without affecting the clean repo
- [ ] `pyrch` (production repo): branch protection on `main` — all changes via PR; PR must pass review before merge
- [ ] Promotion path: prove feature works in `pyrch-dev` → open PR in `pyrch` → PR review agent checks code → merge triggers Render.com deploy
- [ ] Render.com connected to `pyrch` repo only — production service auto-deploys on `main` push; staging service connected to `staging` branch

#### Environments
- [ ] **Development** (`development`): local machine; local PostgreSQL; `.env` file for secrets; `bin/dev` with foreman
- [ ] **Test** (`test`): local machine; separate test database; Minitest; runs on every PR via GitHub Actions CI
- [ ] **Staging / Beta** (`staging`): Render.com preview service; connected to `staging` branch of `pyrch` repo; isolated data, no shared state with production; used for beta tester access and pre-release validation
- [ ] **Production** (`production`): Render.com production service; `main` branch; real user data; GCS for storage; full live API keys

#### Secrets & API Key Management
- [ ] Naming convention: `SERVICE_ENV_PURPOSE` (e.g., `ANTHROPIC_API_KEY_PROD`, `STRIPE_SECRET_KEY_STAGING`)
- [ ] All secrets stored in **Bitwarden** first — before being added to any environment
- [ ] Rails credentials: separate `credentials/development.yml.enc`, `credentials/staging.yml.enc`, `credentials/production.yml.enc` — no shared master `credentials.yml.enc`
- [ ] Render.com: environment variables configured per-service; staging and production get different keys
- [ ] GitHub Actions: secrets stored in repo Settings → Secrets for CI use only
- [ ] `.env.example` in repo: key names only, never values; committed to git so new environments know what keys are needed

#### API Keys to Procure Before Phase 1 (all environments)
- [ ] Anthropic Claude API — dev, staging, prod
- [ ] Stripe — test mode keys (dev + staging); live mode (prod only — never test keys in prod)
- [ ] Mailgun — sandbox (dev); custom domain mg.pyrch.ai (staging + prod)
- [ ] Google Cloud Storage — separate GCS buckets + service accounts per environment
- [ ] VAPID key pair — generate per environment
- [ ] GoodJob — no external API key; PostgreSQL-backed

#### Agent Architecture
Pyrch is built with a team of specialized AI agents. Each must be briefed with this plan before starting work in their area.

| Agent | Role | Active During |
|---|---|---|
| **pyrch-planner** | Maintains this plan; updates phases, decisions, lessons | Always |
| **primary-developer** | Rails/Ruby/JS implementation | All phases |
| **ux-designer** | Screen design, style guide, UI PR reviews | Phase 0 + all phases |
| **security-tester** | Security audits at end of each phase | End of each phase |
| **devops-agent** | Environment setup, CI/CD, deployment, environment promotion | Phase 0, on-demand |
| **api-manager** | Tracks all external APIs, rotates keys, handles version upgrades (e.g., Claude model bumps), monitors per-API cost | Phase 0, ongoing |
| **cost-monitor** | Tracks monthly bills across all services; flags unexpected cost spikes against established baseline | Phase 0, monthly |
| **pr-reviewer** | Reviews every PR before merge: security, standing rules, test coverage, CRITICAL TERMINOLOGY | All phases |
| **marketing-strategist** | Landing page, copy, SEO, referral program, beta acquisition | Phase 4+ |

#### Style Guide (Delivered Before Phase 1 Code Starts)
- [ ] UX designer writes Pyrch style guide: color palette, typography scale, spacing system, component patterns (cards, buttons, badges, modals, bottom sheets), interaction conventions (toasts, form validation, loading states)
- [ ] Style guide is a living reference — primary developer consults it before building any new view; prevents the "unstyled scaffold" anti-pattern from ChoreQuest
- [ ] Design language reference: Spotify mobile/desktop — dark/deeply saturated nav bar, large labels beneath icons, smooth transitions, bright accent for active state, persistent bottom tab bar on mobile
- [ ] Primary developer and UX designer pair on every core feature — walk through one screen at a time; no solo UI work on user-facing pages without UX sign-off

#### Phase 0 Checklist (must be complete before Phase 1 starts)
- [ ] `pyrch-dev` and `pyrch` GitHub repos created; access configured
- [ ] All API keys procured, named per convention, stored in Bitwarden, loaded into each environment
- [ ] Render.com: production service + staging service configured; connected to correct branches
- [ ] All agents briefed with this document
- [ ] Style guide v1 delivered by UX designer
- [ ] PR review agent configured and connected to `pyrch` repo
- [ ] GitHub Actions CI running Minitest on every PR to `pyrch`

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

#### Chore Routine & Household Maintenance Plan
- [ ] `ChoreRoutine` model: `household_id`, `chore_id`, `frequency` (enum: `daily`, `weekly`, `biweekly`, `monthly`), `last_assigned_on`, `notes` — tracks which chores need to happen regularly and when they were last done
- [ ] Parents configure routines per chore: "Clean Room — weekly"; Rue reads this data to suggest what to assign next
- [ ] Rue tool: `get_chore_routine_status` — "The kitchen trash hasn't been assigned in 5 days; it's set to weekly"
- [ ] Rue tool: `suggest_schedule_from_routines` — builds a week's assignment suggestions based on frequency and overdue gaps
- [ ] Parent dashboard: "Household Maintenance" view showing each routine chore, last completion date, and next suggested assignment date

#### Child Accessibility
- [ ] Text-to-speech button on each chore card (child view) — tapping reads the chore name and definition_of_done aloud; for non-readers who can do chores independently without adult help
- [ ] Implemented via Web Speech API (`SpeechSynthesis`) in a Stimulus controller; no external service or API key needed
- [ ] Age-aware Rue feedback on photo analysis: detect child age from `birthday`; if ≤ 7 years old, Rue provides emoji-heavy, picture-first short feedback; if ≥ 8, Rue provides a short written explanation of what passed or failed and why

#### Push Notifications (Phase 2)
- [ ] "Tomorrow's chores not set" notification — sent to household admin at 8 PM local time if no assignments exist for tomorrow for any child
- [ ] Standard notification triggers: chore submitted for review (parent gets push), chore approved (child gets push), chore rejected with note (child gets push)
- [ ] All notification triggers go through a single `NotificationService` — never scattered across jobs and controllers

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

#### Game Session Modes
- [ ] Three play modes configurable per household (parent sets household default; can override per-session grant):
  - **Token mode** — each minute of play costs N tokens; session ends when tokens run out; heartbeat deducts tokens every 60s
  - **Timed mode** — parent grants a fixed duration (30 min, 1 hour); no token cost; heartbeat counts down time
  - **Free play mode** — no token cost, no time limit; parent explicitly enables per session or for a defined window
- [ ] Shared time-management layer for Token mode and Timed mode — same heartbeat loop, same UI; only the currency (tokens vs. minutes) differs; never build two separate implementations
- [ ] 5-minute warning: when ≤ 5 minutes remain (in either token or timed mode), push a browser notification + on-screen toast; if a new game is started after the warning and time runs out mid-game, module shuts off gracefully (score saved first)
- [ ] Parent access to games — adults in the household can play games; game hub visible on parent dashboard; play gate (chore completion) enforced only for `Child` members

#### Leaderboards
- [ ] **Family leaderboard** per game: ranked high scores among all household members (children and adults); visible on the game hub card; drives household competition
- [ ] **Global leaderboard** per game: opt-in high scores across all Pyrch households; display name only (no household names or emails); parent controls whether a child participates in global boards via household settings
- [ ] `GameScore` model gains `leaderboard_eligible: boolean` (default: follows household opt-in setting)
- [ ] Leaderboard UI: top 10 family scores + the current player's personal best; global board shows top 10 with "Your rank: #47" callout if the player has a score

#### Security Audit (Phase 3)

---

### Phase 4 — Monetization + Marketing + Conversational Rue

**Goal:** The app has a paywall, a public face, and Rue can take actions by conversation.

**Deliverables:**

#### Stripe Subscription
**POC validated on ChoreQuest 2026-03-05** — full payment loop working end-to-end in test mode.

- [ ] `gem "stripe", "~> 13.0"` in Gemfile
- [ ] Stripe columns on `Household`: `stripe_customer_id` (unique index), `stripe_subscription_id` (unique index), `subscription_status`; `plan_tier` already added in Phase 1 (default: `trial`)
- [ ] `config/initializers/stripe.rb`: `Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)`
- [ ] Credentials structure: `stripe: { secret_key:, publishable_key:, price_id:, webhook_secret: }`
- [ ] Billing routes: `namespace :billing` with `POST checkout`, `GET success`, `GET cancel`, `POST webhook`, `GET portal`
- [ ] `Billing::CheckoutController#create`: `Stripe::Checkout::Session.create(mode: "subscription", metadata: { household_id: }, success_url:, cancel_url:)`; redirect with `allow_other_host: true`; **button must have `data: { turbo: false }`** — Turbo intercepts external redirects and swallows them silently
- [ ] `Billing::WebhooksController`: `skip_before_action :verify_authenticity_token`; verify `Stripe-Signature` with `Stripe::Webhook.construct_event`; handle: `checkout.session.completed` → set customer_id, subscription_id, plan_tier `paid`, status `active`; `customer.subscription.updated` → sync status; `customer.subscription.deleted` → downgrade to `free`; `invoice.payment_failed` → set `past_due`
- [ ] `Billing::PortalController#create`: `Stripe::BillingPortal::Session.create(customer: household.stripe_customer_id)`; redirect with `allow_other_host: true`
- [ ] Upgrade banner on household admin dashboard: shown when `plan_tier == "free"` or `subscription_status == "past_due"`
- [ ] All feature gates via `PlanPolicy` service object — never scattered across controllers
- [ ] **Production**: register webhook URL (`https://pyrch.ai/billing/webhook`) in Stripe Dashboard → Developers → Webhooks; the dashboard generates a separate `whsec_` secret — different from the local CLI listener secret; add to production credentials

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

#### Support System
- [ ] Customer-facing support chat: parents open a support conversation from Settings → Help
- [ ] **AI-first path**: parent messages answered by Claude in the support context; common issues (billing, PIN reset, adding a child) resolved without human involvement
- [ ] **Human escalation path**: if AI cannot resolve the issue or parent explicitly requests a human, the conversation escalates to a support inbox in the `Admin::` superadmin namespace
- [ ] Superadmin support interface: inbox of escalated conversations; AI drafts a suggested response for each message; superadmin reviews and sends (or edits before sending) — never auto-sends without human review
- [ ] `SupportConversation`: `household_id`, `status` (enum: `open`, `ai_active`, `escalated`, `resolved`), `messages` (jsonb); linked to household for context
- [ ] Rate limit: max 5 open support conversations per household to prevent abuse

#### Beta → Paid Conversion (Phase 4)
- [ ] At beta end, show a conversion screen: "Your Pyrch beta is ending — thank you for being a founder! Continue with Pyrch Family for $12/month."
- [ ] If they don't convert: **silent downgrade** to free tier — children still see their chores, nothing hard-locks
- [ ] "Founding Member" badge on household settings for any beta user who converts to paid (lifetime recognition)
- [ ] Conversion email sequence: day 55 "5 days left on your beta", day 59 "Last day tomorrow", day 60 "Your beta has ended — continue with Pyrch Family"

#### Security Audit (Phase 4)

---

### Phase 5 — Homework Module + Rue Tutor

**Goal:** Parents can track school assignments, kids earn tokens for completing homework. Rue Tutor adds age-appropriate interactive learning games — spelling practice, math drills — that reinforce school skills and earn tokens.

**Deliverables:**

#### Homework Tracking
- [ ] `HomeworkTask`: `title`, `subject`, `due_date`, `points`, `user_id` or `child_id` (polymorphic assignee), `household_id`, `completed_at`
- [ ] Completion tracking: token reward on completion (optional, configurable per task)
- [ ] Homework module card on child home screen
- [ ] Rue suggestions: study time, streak celebrations, upcoming due dates
- [ ] Rue tools: `add_homework_task`, `list_homework_due`, `mark_homework_done`, `get_homework_summary`

#### Rue Tutor (Interactive Learning)
- [ ] Rue Tutor is a child-facing learning module — shown as "Study with Rue" card on the child module home screen
- [ ] **Spelling practice**: parent (or Rue) adds a weekly spelling list; Rue reads each word aloud via SpeechSynthesis; child types it; Rue grades and gives encouraging feedback; earns tokens per correct word
- [ ] **Math help**: age-appropriate drills (addition, subtraction, multiplication, division); Rue generates problems based on child's grade level (derived from `birthday`); earns tokens per completed set
- [ ] **Responsible AI boundaries**: Rue Tutor coaches — it does not do homework for the child; if a child asks for the answer directly, Rue explains the concept and guides them instead
- [ ] `RueTutorSession`: `child_id`, `subject`, `problems_attempted`, `problems_correct`, `tokens_earned`, `completed_at`
- [ ] Parent configures which subjects are active and manages the weekly spelling list in household settings
- [ ] Rue tools: `start_spelling_session`, `start_math_drill`, `get_tutor_progress_for_child`, `update_spelling_list`

#### Security Audit (Phase 5)

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

**POC scope — validated on ChoreQuest 2026-03-04:**
- [x] ActionMailbox setup + Mailgun inbound routing to `/webhooks/inbound_email`
- [x] `SchoolMessage`: `subject`, `raw_body`, `from_address`, `category`, `child_name`, `summary`, `action_item`, `deadline`, `actioned`, `needs_attention`, `parse_status` fields (household-scoped in Pyrch)
- [x] `SchoolCommunicationsMailbox`: matches sender email to parent; silently drops unknown senders
- [x] `ParseSchoolEmailJob` (GoodJob): calls Claude Haiku, returns structured JSON; writes parsed fields back to `SchoolMessage`
- [x] `/school_messages` inbox: "Needs Attention" section at top, color-coded category chips, "Mark Done" button, parse status indicators
- [x] **POC verdict: VALIDATED** — Claude Haiku reliably parses category, child_name, summary, action_item, deadline, needs_attention from both simple and ambiguous school emails; proceed to full module

**Pyrch V2 POC schema (carry forward with household scoping):**
```ruby
SchoolMessage
  household_id:     references (NOT NULL)
  source:           enum ['email', 'sms', 'manual'] (default: 'email')
  subject:          string
  raw_body:         text
  from_address:     string
  category:         enum ['event', 'homework', 'permission_slip', 'absence_alert', 'newsletter', 'announcement', 'unknown']
  child_name:       string (nullable — parsed from email, not a FK; matched to Child later)
  summary:          text
  action_item:      text
  deadline:         date (nullable)
  needs_attention:  boolean (default: false) — AI sets this; drives inbox ordering
  actioned:         boolean (default: false) — parent marks done
  parse_status:     enum ['pending', 'parsed', 'failed'] (default: 'pending')
```

**Mailbox matching rule (from POC):** Match `mail.from.first` against `User.email` (exact, case-insensitive). Silently `return nil` for unknown senders — never bounce (avoids spam loops). In Pyrch, scope the `User` lookup to the household implied by the inbound address.

**Full module (only if POC validates — it does):**
- [ ] Per-household inbound email addresses (not a shared `school@` address) — unique subdomain or `+tag` routing in Mailgun
- [ ] Twilio SMS number per household
- [ ] `CalendarEventProposal` + `HomeworkProposal`: one-tap confirmation creates Event or HomeworkTask
- [ ] Child visibility controls (`adult_only` flag on SchoolMessage)
- [ ] Rue tools: `check_school_inbox`, `get_message_detail`, `action_message`, `confirm_calendar_proposal`, `confirm_homework_proposal`, `dismiss_proposal`
- [ ] Third-party integrations (ClassDojo, Remind, Google Classroom): deferred; schema accepts additional `source` enum values without migration
- [ ] Security audit: Mailgun/Twilio signature validation on all webhook endpoints

**Mailgun credential structure for Pyrch:**
```yaml
# config/credentials.yml.enc
action_mailbox:
  mailgun_signing_key: <HTTP webhook signing key>   # from Mailgun → Sending → Webhooks
mailgun:
  api_key: <Private API key>                         # from Mailgun → Settings → API Keys
  smtp_login: postmaster@mg.pyrch.ai
  smtp_password: <SMTP password>
```

**DNS records on GoDaddy for mg.pyrch.ai:**
- SPF TXT record on mg subdomain
- DKIM TXT record (Mailgun-generated)
- CNAME tracking record (email.mg.pyrch.ai → mailgun.org)
- Two MX records pointing to Mailgun servers

---

## Beta Strategy

### Goal
Beta validates the core experience with real families before opening to paid subscribers. Beta users pay nothing; the app must convert them to paying customers or gracefully downgrade them at the end of the beta window.

### Beta User Acquisition
- [ ] Public beta sign-up page at `pyrch.ai/beta`: simple form (name, email, number of kids); no payment required; manual review by founder before granting access
- [ ] Approved beta users receive a Devise invitation email (via `devise_invitable`); they set a password and sign up normally
- [ ] Beta users flagged on `Household`: `beta_user: boolean` + `beta_started_at: datetime`; receive `plan_tier: 'trial'` with extended window (e.g., 60 days vs. the standard 14-day trial)
- [ ] "Beta" badge shown in the app header for beta households — sets expectations, makes them feel like insiders

### Beta Feedback Integration
- [ ] Feedback form available from day one for beta users (Phase 4 `FeedbackPost` ships alongside or before beta launch)
- [ ] Persistent "Share Feedback" button in the parent nav More sheet for beta households
- [ ] Every Rue capability boundary fallback auto-logs to the feedback board — top missing features surface immediately via vote counts
- [ ] Monthly founder digest: top-voted feedback posts, most common Rue boundary hits, any bugs submitted

### Beta → Paid Conversion
- [ ] At beta end (e.g., day 60), show a conversion screen: "Your Pyrch beta is ending — thank you for being a founder! Continue with Pyrch Family for $12/month."
- [ ] Stripe checkout pre-fills their email; optionally apply a "Founding Member" discount code
- [ ] If they don't convert: **silent downgrade** to free tier — children still see their chores, nothing hard-locks; family keeps using the app on free limits
- [ ] "Founding Member" badge on household settings for any beta user who converts to paid (lifetime recognition; no ongoing discount required)
- [ ] Conversion email sequence: day 55 "5 days left on your beta", day 59 "Last day tomorrow — here's what you've built", day 60 "Your beta has ended — continue with Pyrch Family"

### Environment Promotion Path
```
[Local dev (pyrch-dev repo)]
  → [staging branch of pyrch repo]
  → [staging Render service — beta users test here]
  → [PR to main in pyrch repo → PR review agent + security audit]
  → [merge → production Render service auto-deploys]
```
- Beta runs on **staging** environment (separate Render.com service, separate database, separate GCS bucket)
- When ready to open to all users: run full environment promotion checklist — security audit passed, all standing rules verified, PR reviewer sign-off, UX designer sign-off, cost-monitor baseline established, Stripe live mode keys in production credentials
- Feature flags allow new features to roll out to a subset of production households before full release — same mechanism used for internal testing before beta, and for beta before production

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

### School Communications Hub — POC Learnings (2026-03-04)

**What we built on ChoreQuest as a POC:**
- Mailgun for both inbound (ActionMailbox) and outbound (Devise emails) — single service handles both; use a custom domain (mg.pyrch.ai) from day one, not the sandbox
- Custom domain DNS: SPF TXT, DKIM TXT, CNAME tracking record, two MX records — all on GoDaddy, all completed in under 30 minutes
- ActionMailbox with `:mailgun` ingress — Rails handles Mailgun webhook signature verification automatically; no custom HMAC code needed
- `SchoolCommunicationsMailbox`: sender matched by email address; silently returns `nil` for unknown senders (never bounce — bouncing unknown senders can create spam loops)
- `ParseSchoolEmailJob` (GoodJob): calls Claude Haiku with a structured JSON extraction prompt; writes parsed fields back to `SchoolMessage`
- Inbox UI: "Needs Attention" items surfaced at top; color-coded category chips; "Mark Done" per message; parse status indicator

**Parsing quality verdict:** Claude Haiku reliably extracted category, child_name, summary, action_item, deadline, and needs_attention from both simple and ambiguous emails (multiple children mentioned, vague dates like "this Friday", mixed topics in one email). Reliable enough to build the full module.

**Hard-won technical lessons (do not repeat):**

1. **`ActionView::Base.full_sanitizer` crashes in background jobs.** `ActionView::Base.full_sanitizer.sanitize(...)` raises `ArgumentError` in GoodJob workers because ActionView is not fully initialized outside the render stack. Use `Rails::Html::FullSanitizer.new.sanitize(...)` — comes directly from the `rails-html-sanitizer` gem and works everywhere including jobs.

2. **Claude Haiku wraps JSON in markdown fences despite explicit instructions.** Even with "Respond with ONLY valid JSON, no markdown fences" in the system prompt, Haiku occasionally wraps the output in ` ```json ... ``` `. Always strip fences before `JSON.parse`:
   ```ruby
   text = text.strip
             .gsub(/\A```(?:json)?\n?/, "")
             .gsub(/\n?```\z/, "")
             .strip
   parsed = JSON.parse(text)
   ```

3. **Mailgun sandbox can only send to whitelisted addresses.** The sandbox domain blocks outbound delivery to any non-whitelisted email. For a real product, set up a custom sending domain (mg.pyrch.ai) from the beginning — DNS setup takes under 30 minutes and eliminates all sandbox restrictions. Do not use the sandbox for any user-visible email flow.

4. **Match parent by email, not by token or household.** Identifying which household forwarded an email by matching `mail.from.first` against `User.email` (case-insensitive) is clean, requires no extra fields, and works naturally with how people forward school emails. In Pyrch, scope the `User` lookup to the inbound address's household; silently drop emails that don't match any known user.

5. **`child_name` is a parsed string, not a FK.** The AI extracts a child name from the email text. Store it as a plain string on `SchoolMessage`. Do not attempt FK resolution at parse time — the name may be a nickname, a partial name, or ambiguous. Build a matching UI pass separately where the parent confirms which `Child` record it refers to.

### Stripe / Payments (2026-03-05)

- **`gem "stripe", "~> 13.0"`** — verified working with Rails 7.1 + Ruby 3.3
- **Turbo kills external redirects silently** — any `button_to` or form that redirects off-domain (Stripe Checkout, Stripe Portal) must have `data: { turbo: false }`; without it the 302 fires but the browser never follows it; no error is shown — it just looks broken
- **Webhook controller must skip CSRF** — `skip_before_action :verify_authenticity_token` on the webhook controller only; never skip globally
- **Metadata is how you link Stripe back to your DB** — pass `metadata: { household_id: current_household.id }` on Checkout Session creation; the `checkout.session.completed` webhook can then do `Household.find(session.metadata["household_id"])` cleanly; no need for email matching
- **Two different webhook secrets** — local dev uses the `whsec_` printed by `stripe listen`; production uses a separate `whsec_` from Stripe Dashboard → Developers → Webhooks; keep them in separate credential environments
- **Local dev requires 3 terminals** — Rails server, `stripe listen --forward-to localhost:3000/billing/webhook`, and your command line; the listener must be running before a payment completes or the webhook is never delivered to your app
- **Replay missed events** — `stripe events resend <evt_id>`; get the event ID from `stripe events list --limit 3`; requires the listener to be running at replay time
- **Stripe CLI login** — `stripe login` links the CLI to your Stripe account; confirms with "Done! The Stripe CLI is configured for [account name]"
- **`allow_other_host: true`** — required on both `redirect_to session.url` (Checkout) and `redirect_to portal_session.url` (Portal); Rails blocks cross-host redirects by default in production

### Google Cloud Storage + Active Storage (2026-03-06)

**Infrastructure decisions:**
- Use GCS for Active Storage in production — Render.com's ephemeral disk wipes uploaded files on every deploy; GCS is the correct default for any persistent file storage
- Render Starter plan ($7/month) is the minimum for AI photo analysis — the free tier (512MB RAM) runs out of memory when downloading and processing images with Vips; Starter gives enough headroom
- For POC / early stages: skip Vips resize entirely — send the raw photo to Claude as base64; phone photos are under 5MB which Claude handles fine, and this eliminates the memory spike

**GCS setup sequence (do in this order):**
1. Create a GCS bucket (us-central1 works well with Render US servers)
2. Create a Service Account with `Storage Object Admin` role — **scope to the bucket, not the project**
3. Grant the service account on the bucket's own Permissions tab — do NOT rely on project-level role assignment alone; they are independent
4. Download the JSON key file and store it as structured YAML in Rails production credentials under `gcs.json_key_data`
5. In `storage.yml`, call `.to_json` on the credentials hash: `credentials: <%= Rails.application.credentials.dig(:gcs, :json_key_data).to_json %>` — a raw Ruby hash is not valid YAML and causes a parse error at boot

**Google Workspace org policy gotcha:**
- `iam.disableServiceAccountKeyCreation` is enforced by default on Google Workspace orgs; must disable BOTH the legacy constraint AND `iam.managed.disableServiceAccountKeyCreation` in Organization Policy
- Requires the `Organization Policy Administrator` role — this is separate from `Organization Administrator` and must be granted explicitly
- Org-level IAM is at a different URL/scope than project-level IAM; switch the project picker to the org level to access it

**Common errors and fixes:**
- `YAML syntax error... did not find expected node content while parsing a flow node` — missing `.to_json` on the credentials hash in storage.yml
- `Google::Cloud::NotFoundError: The specified bucket does not exist` — bucket name in credentials does not match the actual GCS bucket name exactly (case-sensitive)
- `Google::Cloud::PermissionDeniedError: does not have storage.objects.create access` — service account needs `Storage Object Admin` granted on the bucket's Permissions tab, not just at project level
- `Ran out of memory (used over 512MB)` — Vips image processing is too heavy for the Render free tier; either upgrade to Starter or skip the resize step

**storage.yml pattern that works:**
```yaml
google:
  service: GCS
  project: <%= Rails.application.credentials.dig(:gcs, :project_id) %>
  credentials: <%= Rails.application.credentials.dig(:gcs, :json_key_data).to_json %>
  bucket: <%= Rails.application.credentials.dig(:gcs, :bucket) %>
```

**Credentials structure:**
```yaml
gcs:
  project_id: "your-gcp-project-id"
  bucket: "your-bucket-name"   # must match GCS console exactly — case-sensitive
  json_key_data:
    type: "service_account"
    project_id: "..."
    private_key_id: "..."
    private_key: "-----BEGIN RSA PRIVATE KEY-----\n..."
    client_email: "..."
    client_id: "..."
    auth_uri: "https://accounts.google.com/o/oauth2/auth"
    token_uri: "https://oauth2.googleapis.com/token"
    auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs"
    client_x509_cert_url: "..."
```

---

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

### Push Notifications — Web Push (VAPID) (2026-03-07)

1. **Service worker 422 bug in Rails 7.1** — Rails' `verify_same_origin_request` CSRF check treats browser-fetched `.js.erb` service worker files as potential cross-origin JS injection attacks, returning 422. Fix: add `protect_from_forgery except: [:service_worker]` to `PwaController`. This is a silent bug that breaks the entire PWA (caching, offline, push) from day one without any visible error.

2. **`webpush` gem v0.3.2 is incompatible with OpenSSL 3.0** — `Webpush.generate_key` raises `OpenSSL::PKey::PKeyError: pkeys are immutable on OpenSSL 3.0`. Workaround: generate VAPID keys using Ruby's native OpenSSL directly — `key = OpenSSL::PKey::EC.generate('prime256v1')`, then base64url-encode the raw bytes. Whether the gem's sending path has the same problem is untested; may need a maintained fork or manual JWT signing for production. Evaluate before committing to the `webpush` gem in Pyrch.

3. **VAPID keys must be in ENV vars, not only in credentials** — the VAPID public key must reach the browser via a meta tag rendered server-side, which means it must be in the shell environment when the server starts. In development, a `.env` file at the project root (read automatically by foreman, which `bin/dev` uses) is the cleanest solution. On Render.com, set as environment variables in the dashboard. Do not store only in Rails encrypted credentials — they cannot be read at boot time for this use case.

4. **Foreman reads `.env` automatically** — Rails' `bin/dev` uses foreman under the hood. Any `KEY=VALUE` pairs in a `.env` file at the project root are automatically injected into the environment for all processes. No need to prefix every `bin/dev` call with manual env var assignments.

5. **Push subscription requires a registered service worker first** — `navigator.serviceWorker.ready` will never resolve if the service worker failed to register (e.g., due to the 422 bug above). The entire push subscription flow silently fails with no visible error. Always verify SW registration in DevTools → Application → Service Workers before debugging push subscription issues.

6. **Browser permission granted does not mean subscription saved** — the user can click Allow in the browser permission prompt, but if the subsequent `pushManager.subscribe()` call or the POST to the Rails endpoint fails, no subscription is stored. These are two separate steps; both must succeed.

7. **Design `push_subscriptions` with a `platform` column from day one** — use `web | ios | android` values. Web Push (VAPID) handles the PWA path. When Hotwire Native wrappers are added later, the native bridge intercepts `pushManager.subscribe()` and registers with APNs or FCM instead, then posts the device token to the same Rails endpoint with `platform: ios` or `platform: android`. All server-side notification logic (triggers, jobs, service layer) is fully reused across platforms with no rework required.

### UI / UX
- **All dynamic content must be inside `<turbo-frame>`** — variables baked in at page load do not update on poll
- **`<details>/<summary>` for zero-JS toggles** — native HTML, no Stimulus needed for simple show/hide
- **Age-appropriate language everywhere on child-facing screens** — no system terms ("Awaiting review", "Rejected")
- **Play gate logic**: `where.not(approved: true)` — not `where(completed: false)` — children can game a `completed` flag
- **POC 6 is the canonical UI reference** — open `public/pocs/poc-6-pyrch-v1.html` before building any new view; do not invent layout or color decisions outside it
- **Custom SVG mascots at small viewBox sizes do not land visually** — a 100x100 SVG illustration built by engineers looks amateurish; defer mascot illustration to a professional designer and use an emoji placeholder (`🦝`) in the interim; do not invest engineering time in SVG mascot assets

---

## Open Decisions

- [ ] **Free plan limits** — marketing strategist report pending; will be added before Phase 4 Stripe work
- [ ] **Pronunciation rollout** — marketing strategist report pending; will inform all copy and launch materials
- [ ] **Chore granularity UX** — UX designer to evaluate: singular granular chores ("take out kitchen trash" + one photo) vs. macro chores with subtasks ("take out all trash" → tasks: kitchen, bathrooms, garage — each with a model photo); macro+subtasks aligns with Phase 2 `ChoreTask` model; get UX recommendation before building the parent chore configuration UI in Phase 2
- [ ] **Rue Tutor placement** — does Rue Tutor live inside the Homework module (Phase 5) as a tab, or as its own standalone module card on the child home screen? Depends on whether learning games are tied to specific school assignments or are standalone enrichment; decide before Phase 5 `HouseholdModuleConfig` is finalized
- [ ] **Global leaderboard opt-in default** — should households be opted into the global game leaderboard by default (discoverable, parents can opt out) or opted out (privacy-first, parents enable)? Marketing value vs. privacy signal tradeoff; decide before Phase 3 leaderboard ships
- [ ] **Hotwire Native / app store path** — when does it make sense to wrap Pyrch in a Hotwire Native shell for iOS and Android app store distribution? The PWA path (Phase 2) covers most users; native wrappers unlock push via APNs/FCM and app store discoverability; the `push_subscriptions.platform` column is designed for this from Phase 2; evaluate timing after the PWA ships and beta feedback is collected

## Resolved Decisions

- [x] **App name** — Pyrch (P-Y-R-C-H), domain pyrch.ai
- [x] **Mascot name** — Rue (raccoon; species changed from owl during UI POC phase; name and personality unchanged)
- [x] **Mascot visual** — deferred to professional designer; `🦝` emoji used as placeholder in all UI; no custom SVG mascot to be built by engineers
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

## Environment & Deployment Architecture

> This section is the authoritative reference for how Pyrch infrastructure is organized across all three environments. Read it before touching secrets, creating Render services, or configuring any external service.

---

### Three Environments

| Environment | Purpose | URL | Hosting |
|---|---|---|---|
| **Development** | Local feature work and debugging | `http://localhost:3000` | WSL2 / Ubuntu 22.04 on Windows 11 |
| **Staging** | Pre-production QA before merging to main | `https://pyrch-staging.onrender.com` (or similar) | Render.com — dedicated web service |
| **Production** | Live app at pyrch.ai | `https://pyrch.ai` | Render.com — web service + worker |

Development runs on the developer's local WSL2 machine (`/home/paul/projects/pyrch`). Staging and production are both Render.com deployments — two entirely separate Render services pointing at the same GitHub repo but different branches.

---

### Git Branching Strategy

```
main ─────────────────────────────────────────── production deploy
        │
        └── staging ──────────────────────────── staging deploy
                  │
                  └── feature/xxx ──────────────── developer works here
```

- **`feature/*` branches** — all development work happens here; PR targets `staging`
- **`staging` branch** — auto-deploys to Render staging on push; integration testing happens here; QA passes here before promotion
- **`main` branch** — auto-deploys to Render production on push; no direct commits; only fast-forward merges from `staging` after QA passes
- **Hotfix exception** — critical production bugs can be branched directly from `main`, applied to both `main` and `staging` immediately after

This is a change from ChoreQuest where `main` was the only branch and deployed directly to production on every push. That pattern is too risky for a live multi-household app.

---

### Render.com Service Configuration

Pyrch requires **four Render services** in production, **three in staging**:

#### Production Services

| Service | Type | Plan | Purpose |
|---|---|---|---|
| `pyrch-web` | Web Service | Starter ($7/mo minimum) | Rails app server (Puma) |
| `pyrch-worker` | Background Worker | Starter ($7/mo) | GoodJob background job processor |
| `pyrch-db` | PostgreSQL | Starter ($7/mo) | Primary database (Render managed) |
| `pyrch-staging-web` | Web Service | Starter | Staging web (see Staging section) |

**Why Starter minimum:** The free tier (512MB RAM) OOMs when Vips processes image uploads. GCS bypasses most Vips work (photos go directly to GCS), but Claude's image analysis still loads the blob into memory. Starter ($7/mo) gives enough headroom. This was learned on ChoreQuest — do not attempt to run AI photo analysis on Render free tier.

#### Staging Services

| Service | Type | Plan | Purpose |
|---|---|---|---|
| `pyrch-staging-web` | Web Service | Starter | Staging Rails app |
| `pyrch-staging-worker` | Background Worker | Starter | Staging GoodJob worker |
| `pyrch-staging-db` | PostgreSQL | Free tier | Staging database (smaller; free is fine) |

#### GoodJob: Separate Worker Process (Not In-Process)

ChoreQuest runs GoodJob in-process (same Puma process as the web server). This causes two problems:
1. Long-running jobs (AI analysis, email parsing) block web threads
2. If the web process restarts (deploy), in-flight jobs are lost

Pyrch uses GoodJob as a **separate Render Background Worker service** with its own start command:

```bash
# Web service start command
bundle exec rails server -b 0.0.0.0 -p $PORT

# Worker service start command
bundle exec good_job start
```

Both services share the same `DATABASE_URL` (same Render PostgreSQL database). GoodJob uses the database queue — no Redis required.

#### Health Check Endpoint

Rails 7.1+ provides `/up` by default (returns 200 when the app is healthy). Configure Render health checks to poll `GET /up` every 30 seconds. No custom endpoint needed.

#### Migrations

Render does NOT run migrations automatically on deploy. Two options for Pyrch:

**Option A (recommended for production):** Add a pre-deploy command in the Render web service settings:
```bash
bundle exec rails db:migrate
```
Render runs this before swapping the new instance in, so zero-downtime deploys apply migrations before traffic switches.

**Option B (manual):** After deploy, use Render Shell (`your service → Shell tab`):
```bash
bundle exec rails db:migrate
```
Use this for emergency rollbacks where you need to apply the migration manually.

Never use `rails db:schema:load` in production — it wipes all data.

---

### Background Jobs & Monitoring

#### Job Backend: GoodJob (PostgreSQL-backed), not Sidekiq+Redis

**Decision: GoodJob.**

Sidekiq requires Redis. On Render.com, a Redis instance costs $10–15/month on top of the existing PostgreSQL service — that is a 40–60% infrastructure cost increase for a startup with single-digit family count. Pyrch already pays for PostgreSQL; GoodJob uses it as the job queue with no additional service.

Sidekiq wins on raw throughput (thousands of jobs/second) and ecosystem maturity. For Pyrch's job volume — photo analysis jobs (one per chore submission), email parsing jobs, email delivery — throughput is irrelevant. The bottleneck is the Anthropic API call, not the queue. GoodJob handles this workload comfortably at any foreseeable Pyrch scale.

GoodJob also provides a built-in web UI (`/good_job`) for inspecting queued, running, and failed jobs. Mount it behind `AdminUser` authentication in `routes.rb`.

**Jobs in scope:**

| Job | Queue | Expected duration | Notes |
|---|---|---|---|
| `AnalyzeChorePhotoJob` | `default` | 5–30s | Anthropic API call; network-bound |
| `ParseSchoolEmailJob` | `default` | 3–15s | Anthropic API call |
| `ActiveStorage::AnalyzeJob` | `default` | <1s | Rails built-in blob metadata |
| Email delivery (ActionMailer) | `mailers` | <2s | Mailgun SMTP |
| Push notification jobs (future) | `default` | <1s | webpush gem |

**Gems to add to Pyrch Gemfile:**
```ruby
gem "good_job", "~> 4.0"
```
No Redis gem. No Sidekiq gem.

#### Worker Process: Separate Render Service (Not In-Process with Puma)

**Decision: always run GoodJob as a separate `pyrch-worker` Render Background Worker.**

The ChoreQuest OOM problem came specifically from `ruby-vips` (libvips image processing library) loading into the Puma process during `ActiveStorage::AnalyzeJob`. Pyrch does not use image variants or libvips — photos are stored and served as-is from GCS, so that specific cause is gone.

However, even without the OOM risk, running jobs in-process with Puma is still wrong for Pyrch:

1. `AnalyzeChorePhotoJob` holds a Puma thread for 5–30 seconds during the Anthropic API call. With a Starter instance (1 CPU, limited threads), this starves web request threads. A child submitting a chore photo blocks other web traffic.
2. In-process jobs die silently on deploy. GoodJob's async mode has a graceful shutdown, but Render's deploy swap is not guaranteed to drain in-flight jobs cleanly unless the worker is a separate service with its own lifecycle.
3. Staging also uses a separate `pyrch-staging-worker` service (already in the Render services table above) — this keeps the separation consistent across environments.

Set `GOOD_JOB_EXECUTION_MODE=external` on the Render web service so the web process never picks up jobs even if the worker is temporarily down.

#### Error Monitoring: Sentry — add it from day one, use the free tier

**Decision: install Sentry on day one, free tier.**

The core problem is that background jobs currently swallow errors silently. `AnalyzeChorePhotoJob` rescues all exceptions and logs to `Rails.logger` — on Render, that means errors appear in the log stream and then scroll off. If a photo analysis job fails for every submission for 6 hours, no alert fires. The family thinks the app is broken. A parent churns.

Render log drain to Papertrail is cheaper (~$7/month for 1GB logs) and simpler, but it only stores logs — you still have to grep through them manually after something goes wrong. Sentry captures the full exception with stack trace, job arguments, user context, and environment at the moment of failure, and sends an email alert.

Sentry free tier gives 5,000 errors/month. At Pyrch's early scale (handful of families, ~20–50 job executions/day), the free tier is effectively unlimited. The paid tier ($26/month) is only needed when the free limit is consistently hit — that is a good problem to have and signals real user volume.

**What to instrument:**
- Background jobs: Sentry captures unhandled exceptions automatically with the Rails integration; remove the blanket `rescue => e` from `AnalyzeChorePhotoJob` and let Sentry capture it (GoodJob will retry the job per its retry policy)
- Web requests: Sentry captures 500 errors automatically
- Rue/AI conversation errors: instrument explicitly where the Anthropic client is called

**The threshold rule:** Sentry is installed from day one. Remove it only if costs become a problem after the free tier is genuinely exhausted.

**Gems to add to Pyrch Gemfile:**
```ruby
gem "sentry-ruby"
gem "sentry-rails"
```

**Initializer pattern:**
```ruby
# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 0.1   # 10% of transactions — keeps performance quota low
  config.profiles_sample_rate = 0.1
  config.environment = Rails.env
  config.enabled_environments = %w[production staging]
end
```

Add `sentry: { dsn: "..." }` to both `staging.yml.enc` and `production.yml.enc`. Do NOT add to development credentials — you want local exceptions to raise normally, not be swallowed into Sentry's dashboard.

#### GoodJob Retry Policy

GoodJob retries failed jobs with exponential backoff by default. Configure explicit retry limits per job class to avoid infinite retry loops on permanent failures (e.g. a malformed photo that will always fail AI analysis):

```ruby
# In each job class
class AnalyzeChorePhotoJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound  # attempt deleted before job ran — don't retry
  # ...
end
```

After 3 failed attempts, GoodJob marks the job `discarded`. Sentry captures each failure. The `ai_verdict` fallback to `NEEDS_REVIEW` ensures no child's submission is silently lost — it surfaces to the parent for manual review.

---

### Secrets Inventory

Every secret is listed here per environment. Secrets are managed two ways in Pyrch:

- **Rails encrypted credentials** — for secrets that belong in the codebase (services the app calls directly); edited with `rails credentials:edit --environment <env>`
- **Render environment variables** — for infrastructure secrets Render itself needs to know (master key, database URL)

#### Development Secrets

Stored in `config/credentials.yml.enc` (encrypted with `config/master.key` — gitignored, local only).

```yaml
# config/credentials.yml.enc (base / development)
secret_key_base: <auto-generated by rails new>

anthropic:
  api_key: <dev key — use a separate Anthropic project or the same key with low limits>

gcs:
  project_id: "pyrch-dev"           # or reuse the prod GCP project with a separate bucket
  bucket: "pyrch-development"       # separate bucket from production — NEVER share buckets across environments
  json_key_data:
    type: "service_account"
    # ... full service account JSON structure (see GCS Lessons Learned section)

mailgun:
  smtp_login: "postmaster@mg.pyrch.ai"
  smtp_password: <mailgun SMTP password>

# action_mailbox uses relay ingress in development — no signing key needed locally
# stripe uses test mode keys in development
stripe:
  secret_key: "sk_test_..."
  publishable_key: "pk_test_..."
  price_id: "price_test_..."         # test mode price ID from Stripe Dashboard
  webhook_secret: "whsec_..."        # printed by `stripe listen` CLI — changes each session
```

Local env file for the master key (never committed):
```
config/master.key   ← gitignored; decrypts config/credentials.yml.enc
```

#### Staging Secrets

Stored in `config/credentials/staging.yml.enc` (encrypted with `RAILS_MASTER_KEY` set as a Render env var on the staging service).

```yaml
# config/credentials/staging.yml.enc
secret_key_base: <generate with `rails secret`>

anthropic:
  api_key: <same key as production OR a separate key with usage limits>

gcs:
  project_id: "pyrch-production"    # can share GCP project
  bucket: "pyrch-staging"           # SEPARATE bucket from production
  json_key_data:
    # ... same structure as development

mailgun:
  smtp_login: "postmaster@mg.pyrch.ai"
  smtp_password: <mailgun SMTP password>
  mailgun_signing_key: <HTTP webhook signing key for staging — same or separate Mailgun route>

action_mailbox:
  ingress_password: <SecureRandom.hex for staging ActionMailbox ingress auth>

stripe:
  secret_key: "sk_test_..."         # test mode — staging never uses live Stripe keys
  publishable_key: "pk_test_..."
  price_id: "price_test_..."
  webhook_secret: "whsec_..."       # from Stripe Dashboard → staging webhook endpoint registration

sentry:
  dsn: "https://...@sentry.io/..."  # Sentry project DSN — from Sentry → Settings → Projects → Client Keys
```

Render environment variables for the staging web service:
```
RAILS_MASTER_KEY=<key that decrypts staging.yml.enc>
RAILS_ENV=production                # Render runs Rails in production mode; staging uses staging credentials
DATABASE_URL=<auto-set by Render PostgreSQL addon>
GOOD_JOB_EXECUTION_MODE=external   # tells GoodJob not to run jobs in the web process
```

**Note on `RAILS_ENV`:** Render services always run `RAILS_ENV=production`. Staging vs production is differentiated by which credentials file is loaded (controlled by `RAILS_MASTER_KEY`). This is the same pattern ChoreQuest uses.

#### Production Secrets

Stored in `config/credentials/production.yml.enc` (encrypted with `RAILS_MASTER_KEY` set as a Render env var on the production service). Only `config/credentials/production.yml.enc` is committed to git — never the key.

```yaml
# config/credentials/production.yml.enc
secret_key_base: <generate with `rails secret`>

anthropic:
  api_key: <live Anthropic API key>

gcs:
  project_id: "pyrch-production"
  bucket: "pyrch-production"        # production bucket — never shared with staging
  json_key_data:
    # ... full service account JSON

mailgun:
  smtp_login: "postmaster@mg.pyrch.ai"
  smtp_password: <mailgun SMTP password>
  mailgun_signing_key: <HTTP webhook signing key from Mailgun → Sending → Webhooks>

action_mailbox:
  ingress_password: <SecureRandom.hex — different value than staging>

stripe:
  secret_key: "sk_live_..."         # LIVE key — never commit; never log
  publishable_key: "pk_live_..."
  price_id: "price_live_..."        # live mode price ID
  webhook_secret: "whsec_..."       # from Stripe Dashboard → Developers → Webhooks (production endpoint)

sentry:
  dsn: "https://...@sentry.io/..."  # Sentry project DSN — same project as staging is fine; environments are tagged separately
```

Render environment variables for the production web service:
```
RAILS_MASTER_KEY=<key that decrypts production.yml.enc>
RAILS_ENV=production
DATABASE_URL=<auto-set by Render PostgreSQL addon>
GOOD_JOB_EXECUTION_MODE=external
```

**Render environment variables for the production worker service** (same secrets, since it connects to the same database and calls the same external APIs):
```
RAILS_MASTER_KEY=<same production master key>
RAILS_ENV=production
DATABASE_URL=<same PostgreSQL URL>
```

---

### Credentials File Map

| File | Committed to git | Decrypted by | Used in |
|---|---|---|---|
| `config/credentials.yml.enc` | Yes (base file — dev/test) | `config/master.key` (local only) | Development, test |
| `config/credentials/staging.yml.enc` | Yes | `RAILS_MASTER_KEY` on Render staging | Staging |
| `config/credentials/production.yml.enc` | Yes | `RAILS_MASTER_KEY` on Render production | Production |
| `config/master.key` | **NO** | N/A | Local decryption of base credentials |
| `config/credentials/staging.key` | **NO** | N/A | Optional local staging credentials edit |
| `config/credentials/production.key` | **NO** | N/A | Optional local production credentials edit |

**Never commit any `.key` file.** Verify `.gitignore` covers all three key files before the first commit.

Edit production credentials from WSL:
```bash
VISUAL=nano RAILS_MASTER_KEY=<value_from_render> rails credentials:edit --environment production
# After editing: git add config/credentials/production.yml.enc && git commit
```

---

### Google Cloud Storage — Per-Environment Buckets

Three separate GCS buckets, same GCP project:

| Environment | Bucket Name | Access |
|---|---|---|
| Development | `pyrch-development` | Developer's local service account key |
| Staging | `pyrch-staging` | Staging service account (can be same SA as production with separate bucket permissions) |
| Production | `pyrch-production` | Production service account — Storage Object Admin role scoped to this bucket only |

**Never point staging at the production bucket.** A broken staging job that deletes or corrupts GCS objects would affect production photos.

`storage.yml` uses environment-conditional config to select the right bucket:
```yaml
# Keep a single 'google' stanza; credentials.yml.enc per environment stores the correct bucket name.
google:
  service: GCS
  project: <%= Rails.application.credentials.dig(:gcs, :project_id) %>
  credentials: <%= Rails.application.credentials.dig(:gcs, :json_key_data).to_json %>
  bucket: <%= Rails.application.credentials.dig(:gcs, :bucket) %>
```

Local development uses the `local` disk service (no GCS needed for most development work):
```ruby
# config/environments/development.rb
config.active_storage.service = :local
```

---

### Mailgun Configuration

One Mailgun account, one custom domain (`mg.pyrch.ai`). Inbound routing differentiates environments:

- **Production inbound:** `school@mg.pyrch.ai` or per-household routing → `POST https://pyrch.ai/rails/action_mailbox/mailgun/inbound_emails/mime`
- **Staging inbound:** Use a separate Mailgun route matching a staging-specific address → `POST https://pyrch-staging.onrender.com/rails/action_mailbox/mailgun/inbound_emails/mime`
- **Development inbound:** `config.action_mailbox.ingress = :relay` — use `rails action_mailbox:ingress:postfix` or `mailman` for local testing

ActionMailbox verifies Mailgun signatures automatically when `ingress = :mailgun`. The `mailgun_signing_key` in credentials enables this. Use different signing keys for staging and production if using separate Mailgun routes, or the same key if both routes share one webhook config.

Outbound email (Devise, notifications) goes through Mailgun SMTP on all environments. Staging should send to safe test addresses only — configure `config.action_mailer.default_url_options` per environment:
```ruby
# production.rb
config.action_mailer.default_url_options = { host: "pyrch.ai", protocol: "https" }

# staging: add a staging.rb or set in staging credentials
config.action_mailer.default_url_options = { host: "pyrch-staging.onrender.com", protocol: "https" }
```

---

### Stripe Configuration

Two separate Stripe mode configurations:

| Environment | Stripe Mode | Keys |
|---|---|---|
| Development | Test mode | `sk_test_` / `pk_test_` from Stripe Dashboard |
| Staging | Test mode | Same test keys as development (or a separate test mode account) |
| Production | Live mode | `sk_live_` / `pk_live_` — set in production credentials ONLY |

**Webhook setup required per environment:**
- **Production:** Register `https://pyrch.ai/billing/webhook` in Stripe Dashboard → Developers → Webhooks; copy the generated `whsec_` secret into production credentials
- **Staging:** Register `https://pyrch-staging.onrender.com/billing/webhook` in Stripe Dashboard → Developers → Webhooks (test mode); copy into staging credentials
- **Development:** Run `stripe listen --forward-to localhost:3000/billing/webhook` in a terminal; the CLI prints a temporary `whsec_` secret — set it in base credentials (it changes each listener session; keep a stable placeholder in credentials and override with ENV var during dev if needed)

Local development requires three terminals: Rails server, `stripe listen`, command line.

---

### Anthropic API

One Anthropic API key per billing account. For Pyrch:

- All three environments can share the same key — usage is billed per token, not per environment
- Consider using Anthropic's project feature to create separate projects for staging vs production if you want independent rate limit monitoring or cost tracking
- Store the key in each environment's credentials file (dev in base credentials, staging/production in their respective encrypted files)
- Never log API keys; never return them in responses; never put them in Rails logs via `config.log_level = :debug` in staging without confirming Anthropic's key doesn't appear in request logs

---

### Environment Variables Quick Reference

Variables set directly on Render (not in credentials files):

| Variable | Web | Worker | Notes |
|---|---|---|---|
| `RAILS_MASTER_KEY` | Yes | Yes | Decrypts the environment's credentials file |
| `RAILS_ENV` | Yes | Yes | Always `production` on Render |
| `DATABASE_URL` | Auto | Auto | Set automatically by Render PostgreSQL addon |
| `GOOD_JOB_EXECUTION_MODE` | `external` | `async` | Web should NOT process jobs; worker processes all |
| `PORT` | Auto | N/A | Render sets this; Puma reads it |
| `WEB_CONCURRENCY` | Optional | N/A | Puma worker count; start with 2 |
| `RAILS_MAX_THREADS` | Optional | N/A | Default 5; set to 5 for Puma + GoodJob thread pool |

Everything else (API keys, database credentials for external services, SMTP passwords) belongs in Rails encrypted credentials, not Render env vars — this way secrets are version-controlled alongside the code that uses them and can be rotated by editing the credentials file rather than updating Render's dashboard.

---

### Deployment Runbook

#### First-time production setup (in order):

1. Create GCP project + three GCS buckets (`pyrch-development`, `pyrch-staging`, `pyrch-production`)
2. Create GCS service accounts and download JSON keys
3. Register Mailgun custom domain `mg.pyrch.ai`; add DNS records on GoDaddy (SPF, DKIM, CNAME, 2x MX)
4. Register Stripe webhooks for production and staging endpoints
5. Create Rails credentials for each environment:
   - `rails credentials:edit` (base/dev)
   - `rails credentials:edit --environment staging`
   - `rails credentials:edit --environment production`
6. Create Render PostgreSQL databases (production: Starter; staging: free)
7. Create Render web services (production + staging); add env vars; set build and start commands:
   - Build: `bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate`
   - Start: `bundle exec rails server -b 0.0.0.0 -p $PORT`
8. Create Render background worker services (production + staging):
   - Start: `bundle exec good_job start`
   - Same env vars as web service
9. Push `staging` branch → confirm staging deploys and loads
10. Merge `staging` → `main` → confirm production deploys and loads

#### Routine deploy (feature → staging → production):

```bash
# 1. Development: work on feature branch
git checkout -b feature/my-feature
# ... make changes, test locally ...
git push origin feature/my-feature

# 2. Open PR targeting staging branch; merge when approved
# Render auto-deploys staging on merge

# 3. QA on staging (https://pyrch-staging.onrender.com)
# If migration is needed: Render staging → Shell → bundle exec rails db:migrate

# 4. Merge staging → main (fast-forward only, no merge commit)
git checkout main
git merge --ff-only staging
git push origin main
# Render auto-deploys production

# 5. Check Render production → Logs for errors
# If migration is needed: Render production → Shell → bundle exec rails db:migrate
```

#### Rollback:

Render Dashboard → your service → Deploys → click any previous successful deploy → "Redeploy". This does NOT roll back the database — if the previous code is incompatible with the current schema, you must also run a down migration manually in the Render shell.

---

### Files That Must Never Be Committed

```
config/master.key
config/credentials.yml.enc          ← base credentials (contains dev secrets)
config/credentials/staging.key
config/credentials/production.key
.env
.env.*
log/*
tmp/*
```

Verify `.gitignore` covers all of these before creating the Pyrch repo. The `config/credentials.yml.enc` rule is different from ChoreQuest: ChoreQuest accidentally tracked this file and had to `git rm --cached` it mid-project (see commit `4eb9374`). Start Pyrch with it gitignored.

Only these credential files should be in git:
```
config/credentials/staging.yml.enc
config/credentials/production.yml.enc
```

---

*Last updated: 2026-03-07. Synthesized from rails-architect, project-manager, pyrch-planner, and primary-developer agent reports. Rue lessons added after ChoreQuest implementation and debugging session. School Communications Hub POC validated on ChoreQuest; Phase 8 POC scope marked complete with learnings captured. GCS + Active Storage lessons added after ChoreQuest production file storage setup. Push notification (Web Push / VAPID) lessons added. UI POC 6 approved as canonical design reference; Rue mascot species changed from owl to raccoon; SVG mascot work deferred to professional designer; emoji placeholder pattern established.*
