# Current Sprint — "Polish the Child Experience"

> Last updated: 2026-03-05 by primary-developer agent
> Previous sprint "Lock the Doors" fully complete — all items S1–S4, H1, H2, B1, B2, B3, M1 done and committed (ccb405b).

---

## ✅ DONE — Item 4: Child Status Language

**Goal:** Replace clinical adult-facing status labels on the child's page with age-appropriate language.

**Files changed:**
- `app/views/children/show.html.erb` — replaced all status labels (replace_all):
  - `"Awaiting review"` → `"Being checked... 👀"`
  - `"Rejected"` → `"Try again! 🔄"`
  - `"Completed ✓"` → `"Done! ⭐"`

---

## ✅ DONE — Item 5: Sign-in Error Styling

**Investigation finding:** `flash[:alert]` is already rendered globally in the layout's `<main>` section (outside auth guards), so Devise login failures already display a styled red banner. No code change needed.

---

## ✅ DONE — B4: Child Play Button Nav Sync

**Fix applied:** Moved `render 'bottom_nav'` inside the `<turbo-frame id="chore_status">` block in `app/views/public/show.html.erb`. Removed the redundant outer `todays_ready` recomputation. The bottom nav now re-renders on every 15-second poll so the Play button state stays in sync.

---

## ✅ DONE — PIN Code Visibility

**Fix applied:** `app/views/children/index.html.erb` — replaced plaintext `<div>PIN: ...></div>` with a `<details>/<summary>` Show/Hide toggle (zero JS required).

---

## ✅ DONE — School Communications Hub POC

**Goal:** Forward school emails to `school@mg.pyrch.ai` and have Rue parse them into structured summaries with action items and deadlines. Parents see a clean inbox UI.

**Files created:**
- `db/migrate/20260305020000_create_school_messages.rb` — school_messages table with category, child_name, summary, action_item, deadline, actioned, needs_attention, parse_status
- `app/models/school_message.rb` — belongs_to :parent, scopes: needs_attention, actioned, recent
- `app/mailboxes/school_communications_mailbox.rb` — receives email to school@mg.pyrch.ai, creates SchoolMessage, enqueues ParseSchoolEmailJob
- `app/jobs/parse_school_email_job.rb` — calls Claude claude-haiku-4-5, returns structured JSON, updates message fields
- `app/controllers/school_messages_controller.rb` — authenticate_parent!, index (needs_attention + recent), update (mark done)
- `app/views/school_messages/index.html.erb` — Tailwind inbox with Needs Attention section, empty state
- `app/views/school_messages/_message_card.html.erb` — color-coded category chips, spinner for pending, warning for failed parse, action item + deadline display, Mark Done button

**Files modified:**
- `app/mailboxes/application_mailbox.rb` — added routing rule for school@mg.pyrch.ai → :school_communications
- `app/models/parent.rb` — added has_many :school_messages, dependent: :destroy
- `app/mailers/application_mailer.rb` — updated default from to noreply@mg.pyrch.ai
- `config/environments/production.rb` — added Mailgun SMTP settings, action_mailbox.ingress :mailgun
- `config/environments/development.rb` — added action_mailbox.ingress :relay
- `config/routes.rb` — added resources :school_messages, only: [:index, :update]
- `app/views/layouts/application.html.erb` — added "School" nav link (desktop + mobile hamburger) for parent_signed_in? section

**ActionMailbox install ran:** `rails action_mailbox:install` + `rails db:migrate`
Migration `20260305014740_create_action_mailbox_tables` applied (action_mailbox_inbound_emails table).
Migration `20260305020000_create_school_messages` applied.

**Credentials to add manually (rails credentials:edit --environment production):**
```yaml
action_mailbox:
  mailgun_signing_key: <HTTP webhook signing key from Mailgun>

mailgun:
  api_key: <Private API key from Mailgun>
  smtp_login: postmaster@mg.pyrch.ai
  smtp_password: <SMTP password from Mailgun>
```

**Mailgun webhook to configure:**
- URL: `https://chorequest.onrender.com/rails/action_mailbox/mailgun/inbound_emails/mime`
- Method: POST
- In Mailgun dashboard: Routes → Create Route → match recipient `school@mg.pyrch.ai` → forward to the webhook URL above

---

## After This Sprint
Next priorities: confetti celebration animation on chore approval, photo preview before submission, AI status language during pending analysis, and the parent Settings page redesign.
Full prioritized backlog: run the `project-manager` agent or see `CLAUDE.md` Ideas Backlog.
