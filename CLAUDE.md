# ChoreQuest — Claude Context

## Project Summary
Rails 7.1 app that lets parents assign chores to children, who earn tokens redeemable for game time. Deployed on Render.com with a PostgreSQL database.

## Tech Stack
- Ruby on Rails 7.1, PostgreSQL
- Tailwind CSS, Stimulus JS, Importmap
- Devise (Parent auth + AdminUser auth)
- Deployed on Render.com via GitHub

## Key Architecture Notes
- Games are static HTML files in `public/games/` (not Rails views)
- `config.public_file_server.enabled = true` is required on Render.com (no NGINX)
- Game sessions use a heartbeat system — JS polls `/game_sessions/:id/heartbeat` every 60s to deduct tokens
- Seeds use `find_or_create_by!` — safe to re-run without wiping data

## Ideas Backlog
- [ ] Stripe payments — $10/month subscription, likely with a free plan tier
- [ ] Fix the navigation
- [ ] Make app more mobile friendly
- [ ] Add mobile navigation bar to the bottom of the kids app
- [ ] Make app a Progressive Web App (PWA) with push notifications (parent notified when child submits photo, child notified when tokens awarded)
- [ ] Assignment scheduler — drag chores onto a calendar to assign them to a child (replace the current form-based flow)
- [ ] Dashboard: completed chores feed showing each completion with its photo proof
- [ ] Real-time chore verdict updates — after a child submits a photo, the public view should auto-update when AI (or parent) approves/rejects without requiring a page reload (Turbo Streams or polling)
- [ ] Child page: show token balance + chore progress bar at top ("3/4 chores done — 1 more to go!")
- [ ] Child page: age-appropriate status language — "Mom is checking..." not "Awaiting review", "Try again!" not "Rejected"
- [ ] Child page: photo preview before submission so kids can retake a bad photo before it gets rejected
- [ ] Child page: celebration animation (confetti + "+10 tokens!") when a chore is approved
- [ ] Child page: collapse/hide the 90-day upcoming chores section by default — focus child on today only
- [ ] BUG (security): Chore assignments index view has unscoped `ChoreAssignment.includes(...)` query at line 100 — leaks all parents' assignment data to any logged-in parent; move query to controller scoped to `current_parent`
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
- [ ] [Marketing] Build a public landing page with above-the-fold headline ("Your Kids Earn Their Screen Time. No More Nagging."), a looping 8-second demo video of the photo-submission-to-game-unlock flow, and a "Start Free — No Credit Card" CTA button
- [ ] [Marketing] Write and publish 4 SEO blog posts targeting high-intent long-tail keywords: "kids earn screen time for chores," "app that rewards kids for chores," "how to get kids to do chores without nagging," and "best chore apps for kids" — each 1,200–1,800 words with a natural ChoreQuest mention
- [ ] [Marketing] Post a founder story on r/Parenting and r/daddit — a genuine "I built this for my own kids" post with a GIF or 30-second screen recording showing a child submitting a chore photo and unlocking game time (post Tuesday–Thursday 8–10 AM EST)
- [ ] [Marketing] Record and post 3 TikTok/Instagram Reels showing the end-to-end ChoreQuest flow (child takes photo → AI approves → tokens awarded → game unlocked) targeting #parentinghacks #choresforkids #screentime — post 3x/week for 8 weeks
- [ ] [Marketing] Implement a referral program: unique referral link per parent account, "Give 1 month / Get 1 month" reward structure, and a one-tap post-approval share prompt ("Share this moment with another parent") that pre-fills a message with the referral link
- [ ] [Marketing] Add "Why no app store?" section to the landing page — turn the PWA-only approach into a trust signal: "We're parents too. App stores take 30% of every subscription. By skipping them, we keep the price low and pass the savings to your family. Add to your home screen in 2 taps — it works just like a native app."
