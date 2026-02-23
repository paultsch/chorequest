Goal

Design for token-based game play: charge tokens per minute of game time; when tokens run out, game ends.

Requirements

- Child can play only after today's chores complete.
- Each minute of play deducts N tokens (configurable).
- When token balance reaches 0, the game session ends and child is redirected out of the game.
- Parents can top up tokens via approvals or token transactions.

High-level approach

1. Server-side authoritative model

- Use `GameSession` to represent a child's play session (belongs_to :child, :game).
- `GameSession` fields: `child_id`, `game_id`, `started_at`, `ended_at`, `duration_minutes` (integer), `stopped_early` (bool).
- Tokens are represented via `TokenTransaction` records. Positive amounts add tokens; negative amounts deduct.

2. Reserving vs charging

Option A (recommended): Charge per minute, recorded as negative `TokenTransaction` entries periodically from server.
- On session start, create `GameSession` with `started_at = Time.current` and `duration_minutes = 0` (live session).
- Client (browser) sends a heartbeat every 30s-60s to `GameSessionsController#heartbeat(session_id)`. Server calculates elapsed minutes since last heartbeat and creates negative `TokenTransaction` entries accordingly (e.g., -1 token per minute).
- If token balance reaches zero, server responds to heartbeat with `ended: true` causing client to stop game.
- On explicit stop, finalize `ended_at` and `duration_minutes`.

Option B (simpler): Reserve upfront
- Require child to spend tokens up-front for a requested duration (e.g., 5 tokens per minute * requested minutes). This prevents overspend but requires UI for selecting minutes.

3. Preventing cheating

- Keep server-side deductions authoritative: client cannot decrement locally only. Server validates and deducts based on heartbeats and current balance.
- Use short heartbeats (30-60s) to keep the UI responsive.
- Consider WebSocket / Turbo Streams for real-time notifications (parent approval, session ended due to 0 balance).

4. UX flow

- Child clicks "Play games" -> check completed chores and token balance.
- Show a play menu: choose a game and optionally select duration (or use unlimited until tokens run out).
- Start session: create `GameSession`, begin heartbeats.
- During play, show remaining tokens and elapsed time.
- If tokens reach 0, stop session and redirect to child dashboard.

5. Implementation steps

- Add API endpoints:
  - POST `/children/:id/play` (already created) — validate and return play menu / redirect.
  - POST `/game_sessions` — start session (creates `GameSession`).
  - POST `/game_sessions/:id/heartbeat` — deduct tokens and return `ended` flag.
  - POST `/game_sessions/:id/stop` — stop session and finalize duration.

- Backfill `GameSession` model validations and add `stopped_early` flag.
- Add client-side heartbeat JS in game pages to call the heartbeat endpoint.
- Add background job for reconciliation and cleanup (optional).

6. Token price configuration

- Introduce an app config or DB table for game pricing: tokens per minute per game.

7. Edge cases

- Concurrent sessions: prevent multiple active sessions for same child.
- Race conditions on balance: use DB transactions when creating TokenTransaction and checking balance (SELECT FOR UPDATE).

Next steps (I can implement these in order):
1. Add `play` route + controller action (done).
2. Add `GameSessionsController#create`, `heartbeat`, `stop` endpoints and minimal JS heartbeat stub in the game page.
3. Add token-per-minute config and server-side deduction logic.
4. Add client UX for showing remaining tokens and ending the game when tokens run out.

Which of these implementation steps should I start next? (I recommend step 2: create session endpoints and a simple heartbeat.)
