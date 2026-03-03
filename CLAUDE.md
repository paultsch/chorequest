# ChoreQuest — Claude Context

## Project Summary
Rails 7.1 app that lets parents assign chores to children, who earn tokens redeemable for game time. Deployed on Render.com with a PostgreSQL database.

## Tech Stack
- Ruby on Rails 7.1, PostgreSQL
- Tailwind CSS, Stimulus JS, Importmap
- Devise (Parent auth + AdminUser auth)
- Deployed on Render.com via GitHub

## Pyrch Planning
ChoreQuest is a prototype. The production app being planned is **Pyrch**. The master plan lives at `.claude/pyrch-plan.md`.
- When any Pyrch architectural decision is made during a session, update `.claude/pyrch-plan.md` immediately
- When a Pyrch phase item is completed, check it off in the plan
- When a new lesson is learned that applies to Pyrch, add it to the Lessons Learned section

## Key Architecture Notes
- Games are static HTML files in `public/games/` (not Rails views)
- `config.public_file_server.enabled = true` is required on Render.com (no NGINX)
- Game sessions use a heartbeat system — JS polls `/game_sessions/:id/heartbeat` every 60s to deduct tokens
- Seeds use `find_or_create_by!` — safe to re-run without wiping data

## Ideas Backlog
- [ ] Chore analytics dashboard — show parents (and eventually surface to AI) which chores have been assigned recently, completion rates per chore, per-child engagement trends, and overdue/skipped patterns; use this data to suggest what needs to be assigned next or flag chores that are consistently skipped
- [ ] Sign in / sign up pages: add styled error notifications — Devise validation errors (wrong password, email taken, etc.) are currently unstyled or invisible; display them as a red alert banner above the form so users know what went wrong
- [ ] Stripe payments — $10/month subscription, likely with a free plan tier
- [ ] Fix the navigation
- [ ] Make app more mobile friendly
- [ ] Add mobile navigation bar to the bottom of the kids app
- [ ] Make app a Progressive Web App (PWA) with push notifications (parent notified when child submits photo, child notified when tokens awarded)
- [ ] PWA iOS install banner: iOS Safari never shows an automatic "Add to Home Screen" prompt — add a custom in-app banner that detects iOS Safari + not already in standalone mode (`window.matchMedia('(display-mode: standalone)').matches`) and shows a one-time instructional nudge: "Tap Share → Add to Home Screen for the best experience"; dismiss to localStorage so it only appears once
- [ ] PWA iOS: must be opened in Safari to install — Chrome/Firefox on iOS are just Safari under the hood and cannot install PWAs; add a small "open in Safari" note if the user is on iOS but not in Safari (detect via user agent)
- [ ] PWA Android/Chrome: hook the `beforeinstallprompt` event to show a native "Install App" button — Chrome fires this automatically when PWA criteria are met; intercept it and surface a button in the nav or a banner so users don't miss it
- [ ] Assignment scheduler — drag chores onto a calendar to assign them to a child (replace the current form-based flow)
- [ ] Dashboard: completed chores feed showing each completion with its photo proof
- [ ] Real-time chore verdict updates — after a child submits a photo, the public view should auto-update when AI (or parent) approves/rejects without requiring a page reload (Turbo Streams or polling)
- [ ] Child page: show token balance + chore progress bar at top ("3/4 chores done — 1 more to go!")
- [ ] Child page: age-appropriate status language — "Mom is checking..." not "Awaiting review", "Try again!" not "Rejected"
- [ ] Child page: photo preview before submission so kids can retake a bad photo before it gets rejected
- [ ] Child page: celebration animation (confetti + "+10 tokens!") when a chore is approved
- [ ] Child page: collapse/hide the 90-day upcoming chores section by default — focus child on today only
- [ ] BUG (security): Chore assignments index view has unscoped `ChoreAssignment.includes(...)` query at line 100 — leaks all parents' assignment data to any logged-in parent; move query to controller scoped to `current_parent`
- [ ] [CRITICAL BUG - Security]: `ChildrenController` is missing `authenticate_parent!` — unauthenticated users can GET /children, GET /children/new, and POST /children with no auth enforcement; add `before_action :authenticate_parent!` at the class level
- [ ] [CRITICAL BUG - Security]: `TokenTransactionsController` has no authentication guard — any unauthenticated HTTP client can POST /token_transactions with an arbitrary `child_id` and `amount` to grant or drain tokens for any child in the system; add `before_action :authenticate_parent!` and validate `child_id` belongs to `current_parent`
- [ ] [CRITICAL BUG - Security]: `GameSessionsController` has no authentication, `set_game_session` uses unscoped `GameSession.find`, and `create` accepts user-controlled `child_id` without ownership check — an attacker can manipulate any child's game session or token balance; add auth and scope all lookups to `current_parent`
- [ ] [CRITICAL BUG - Security]: `ChoreAssignmentsController` is missing `authenticate_parent!` and the `create` action accepts `child_id` from params without validating it belongs to `current_parent` — a parent can assign chores to another parent's child; add `before_action :authenticate_parent!` and validate child ownership in `create`
- [ ] [HIGH BUG - Security]: `GameSessionsController#create` accepts user-controlled `duration_minutes` from params with no minimum value check — submitting `duration_minutes: 0` creates a free session, negative values grant tokens; enforce a server-side minimum of 1
- [ ] [HIGH BUG]: Layout `application.html.erb` calls `Child.find(session[:child_id])` which raises `ActiveRecord::RecordNotFound` (500 error) if the child record was deleted after the session was created; replace with `find_by` and add a nil guard to clear the stale session gracefully
- [ ] [MEDIUM BUG - Security]: `GameScoresController#create` accepts unauthenticated score submissions with arbitrary `child_id` and `game_id` params (CSRF is intentionally skipped), allowing score poisoning for any child; scope score creation to a verified session or child token
- [ ] Settings page (`parents/edit`) is a bare unstyled scaffold — needs profile card, name/email fields, password change section, and account deletion danger zone
- [ ] Children index: hide PIN codes behind a "Show" toggle instead of displaying plaintext — any bystander can read every child's PIN
- [ ] Dashboard approval queue: replace wide 7-column table with mobile-friendly cards on small screens — large photo, thumb-friendly Approve/Reject buttons
- [ ] Dashboard: add per-child today's status summary ("Emma — 2/3 chores done") so parents can answer "did my kid do their chores?" without digging
- [ ] Token transactions: add child filter pills + color-code positive (green, earned) vs negative (red, spent) amounts; show per-child balance summary
- [ ] Children index: remove redundant "Parent: Alice" label from child cards — replace with something useful like last completed date or current streak
- [ ] Dashboard + children index: add a quick "+ Grant Tokens" button per child to skip the 3-click navigate-to-new-transaction flow
- [ ] Chore assignments calendar: show chore names (or at least a count badge) on marked dates — dots alone don't tell parents what's scheduled
- [ ] BUG: "Play Games" gate on children/show checks `completed: true` but should check `approved: true` — kids can bypass the gate by self-marking chores done before parent reviews
- [ ] Assignment form: add "repeat weekly" checkbox to schedule a chore every week for N weeks without using the date range picker
- [ ] Assignment form / chore settings: toggle to enable or disable AI photo analysis per chore assignment — some chores don't need AI review, others always should
- [ ] Dashboard: per-child status row showing token balance, today's completion rate ("2/3 chores done"), and pending approval count badge
- [ ] Dashboard: "Today at a Glance" panel — which children have submitted chores awaiting approval, who hasn't started today's chores, and any overdue/missed assignments
- [ ] Nav: pending approval badge (red dot or count) on the Dashboard link so parents notice items without having to navigate there
- [ ] Dashboard: bulk approve/reject UI — checkboxes per attempt + "Approve All" button (controller bulk_update action already exists, no UI exposes it)
- [ ] Dashboard: lightbox for photo review instead of opening a new browser tab
- [ ] Token transactions: per-child filter pills so parents with multiple kids can view one child's ledger at a time
- [ ] Children index / show: one-tap "Copy Link" button for each child's public chore URL
- [ ] Scheduler: show completion status on calendar chips (colored border or icon: done ✓ / pending review 🕐 / rejected ✗) — currently all chips look identical regardless of status
- [ ] Scheduler month view: "+N more" overflow indicator when a day cell has more chips than fit — currently they silently clip
- [ ] Children index: quick "Assign Chore" shortcut per child card to skip navigating to the scheduler
- [ ] Scheduler: recurring assignment UI — backend already supports date-range bulk creation, but the drag-and-drop UI only supports dropping to one day at a time
- [ ] Mobile scheduling: figure out the UX for toggling photo-required on chore assignments from a mobile device — the current desktop sidebar + drag-and-drop pattern doesn't translate well to touch; options include a bottom sheet, a long-press context menu on a chip, or a dedicated mobile scheduling flow
- [ ] BUG: Parent hamburger menu is completely broken on mobile — the `data-nav-target="menu"` dropdown block is missing from the parent signed-in section in `application.html.erb`; logged-in parents on mobile have no way to navigate between pages
- [ ] BUG: Scheduler — newly added chore assignments do not appear on the child's public page; investigate whether the assignment's scheduled_on date matches today's date as the controller queries it, or whether the child's turbo-frame poll interval is too slow to pick it up promptly
- [ ] Scheduler: when a parent adds or removes a chore assignment for today, the child's public page should reflect the change without a manual reload — the 15-second turbo-frame poll will eventually catch it, but consider triggering a reload on `visibilitychange` (tab refocus) so the child sees fresh data the moment they switch back to the tab
- [ ] Child chore submission: add optional "note to reviewer" text field on new_attempt form — pass the note text to AnalyzeChorePhotoJob so the AI prompt includes it when deciding to approve/reject
- [ ] Child chore submission: show "AI is checking... 🤖" status immediately after submission (while status is pending and AI job is running), then switch to "Your grownup is checking... 👀" only if AI returns inconclusive/needs-human-review — avoid "mom/parent" language to stay relationship-neutral
- [ ] Child chore submission: after AI finishes analyzing, auto-update the chore status on the child's page without requiring a refresh — the 15-second turbo-frame poll handles parent approvals but AI results come back faster; consider a shorter poll interval (3–5s) while a pending attempt exists, falling back to 15s when none do
- [ ] BUG: Child "Play" button in bottom nav doesn't sync with Turbo Frame polling — `todays_ready` is computed outside the turbo-frame so the bottom nav Play button stays locked even after the 15-second poll approves chores; child sees "Play!" in main content but a grayed-out button in the nav bar
- [ ] BUG: Child bottom nav token balance is a non-interactive fake nav item — it looks tappable but does nothing; either link it to a token history screen or remove it from the nav bar
- [ ] Nav: replace parent mobile hamburger with a 4-tab bottom navigation bar — Today (Dashboard, with pending badge), Kids (Children), Schedule (Assignments), More (sheet with Chores, Tokens, Settings, Sign Out); pending approval badge must be visible in the bottom bar at all times
- [ ] Nav: slim parent top bar to logo-only on mobile — all nav moves to the bottom bar, freeing screen space for content; keep full top nav on md+ screens
- [ ] Nav: add active state styling to all nav items — use `current_page?` or controller checks to highlight the current page with a filled icon or stronger color; neither parent nor child nav currently shows which page is active
- [ ] Nav: hide footer on mobile — copyright text adds no value for a parent approving photos; add `hidden md:block` to the footer element
- [ ] Nav: increase hamburger button tap target to minimum 44×44px (currently ~32px); also ensure all child bottom nav items use `flex-1` so they stretch to equal thirds rather than relying on padding for tap area
- [ ] Nav: add shake animation + "Finish your chores first!" inline message when a child taps the locked Play button — currently tapping the disabled button is silently ignored, which reads as broken to a child
- [ ] Nav: add `safe-area-inset-top` padding to the public child page main content wrapper for PWA mode on iOS — without it the status bar overlaps content when installed to home screen
- [ ] [Marketing] Build a public landing page with above-the-fold headline ("Your Kids Earn Their Screen Time. No More Nagging."), a looping 8-second demo video of the photo-submission-to-game-unlock flow, and a "Start Free — No Credit Card" CTA button
- [ ] [Marketing] Write and publish 4 SEO blog posts targeting high-intent long-tail keywords: "kids earn screen time for chores," "app that rewards kids for chores," "how to get kids to do chores without nagging," and "best chore apps for kids" — each 1,200–1,800 words with a natural ChoreQuest mention
- [ ] [Marketing] Post a founder story on r/Parenting and r/daddit — a genuine "I built this for my own kids" post with a GIF or 30-second screen recording showing a child submitting a chore photo and unlocking game time (post Tuesday–Thursday 8–10 AM EST)
- [ ] [Marketing] Record and post 3 TikTok/Instagram Reels showing the end-to-end ChoreQuest flow (child takes photo → AI approves → tokens awarded → game unlocked) targeting #parentinghacks #choresforkids #screentime — post 3x/week for 8 weeks
- [ ] [Marketing] Implement a referral program: unique referral link per parent account, "Give 1 month / Get 1 month" reward structure, and a one-tap post-approval share prompt ("Share this moment with another parent") that pre-fills a message with the referral link
- [ ] [Marketing] Add "Why no app store?" section to the landing page — turn the PWA-only approach into a trust signal: "We're parents too. App stores take 30% of every subscription. By skipping them, we keep the price low and pass the savings to your family. Add to your home screen in 2 taps — it works just like a native app."
- [ ] Co-parent / household accounts — allow a second adult to be invited to a parent account so both can assign chores, approve photo submissions, and view the dashboard without sharing login credentials; invited co-parent gets full parent-level access scoped to that household's children only
- [ ] Netflix-style profile picker for shared devices — new route at `/` (or `/profiles`) shows all household members as large circular avatars on a dark full-screen background; child taps their avatar → large PIN keypad modal (not native keyboard — too small for kids, render 10 big number buttons + backspace) → correct PIN redirects to their existing `/public/:token` URL (no new session system needed); parent taps their avatar → standard Devise login; localStorage stores `{ profile_type: 'child', token: '...', name: 'Emma' }` so next visit shows "Continue as Emma" with one big tap target + small "Switch" link; authenticated parent can tap any child avatar to preview their view without entering the child's PIN; "Switch Profile" replaces the dead non-interactive token balance slot in the child bottom nav; if a parent regenerates a child's token, catch stale localStorage with a graceful "Your link changed — ask a parent" message rather than a broken screen; particularly useful for shared tablets/iPads
