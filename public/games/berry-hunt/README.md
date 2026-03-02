# Pyrch's Berry Hunt

**Slug:** `berry-hunt`
**Age bracket:** Little Pyrch (4–6)
**Orientation:** Portrait
**Educational goal:** Counting 1–10, number recognition, one-to-one correspondence

---

## How to Play

Berries appear on a leafy green stage. The child counts the berries, then taps the matching number from four large, colorful buttons. No timers, no pressure — just counting!

- **Correct answer:** Pyrch celebrates with a happy bounce, confetti flies, and the round advances.
- **Wrong answer:** Pyrch shakes his head gently, the berries wiggle to invite a recount, and the child tries again (no score penalty, no shame).

---

## Levels

| Level | Berry range | Unlocks after |
|-------|------------|---------------|
| 1     | 1–5        | Start         |
| 2     | 1–7        | 5 correct in a row on Level 1 |
| 3     | 1–10       | 5 correct in a row on Level 2 |

Level 3 is the final level and loops indefinitely with increasing berry counts.

---

## Token Integration

- Reads `?session_id=` from the URL to identify the active GameSession.
- Fires a `POST /game_sessions/:id/heartbeat` every 60 seconds while the game is active.
- Displays live token balance in the top bar.
- If tokens run out, Pyrch appears sad and the child is prompted to go do chores.
- `POST /game_sessions/:id/stop` is called on page unload.

---

## Mascot: Pyrch

Pyrch is a round golden-yellow cartoon bird with teal feather accents, big expressive eyes, and a small orange beak. Three emotional states are used:

- **Happy (start/level-up screens):** Wings raised, big smile, bright eyes.
- **Normal (in-game):** Gentle bob animation, slight smile.
- **Sad (out-of-tokens screen):** Drooping crest, heavy eyelids, tear drop.

All mascot graphics are inline SVG — no external assets required.

---

## Hooking into Rails

Add the game to `db/seeds.rb` or via console:

```ruby
Game.find_or_create_by!(name: "Berry Hunt") do |g|
  g.description      = "Count berries with Pyrch! A counting game for little learners."
  g.path             = "/games/berry-hunt/index.html"
  g.token_per_minute = 1
  g.min_age          = 4
  g.max_age          = 6
end
```

Then update `children_controller.rb` and `public_controller.rb` to route to this game when its name matches:

```ruby
elsif game.name.to_s.downcase.include?('berry')
  "/games/berry-hunt/index.html?session_id=#{gs.id}"
```

---

## Technical Notes

- Fully self-contained — no external CDN dependencies.
- No hover interactions — all controls work with touch.
- Minimum tap target: 60×60px for answer buttons, 44px for any interactive element.
- Berry sizes scale down (34→30→26px) as counts increase so all berries fit in the stage area.
- Berries are CSS-only divs with `::before`/`::after` pseudo-elements for the stem and leaf.
- Heartbeat is paused when the browser tab is hidden (Page Visibility API) and resumes on return.

---

## Future Enhancements

- [ ] "Tap each berry to count it" mode (one-to-one correspondence practice)
- [ ] Spoken audio for Pyrch's voice lines (Web Speech API or pre-recorded clips)
- [ ] Bonus round: Pyrch hides some berries behind a bush — count what you can see
- [ ] Streak tracker — show a flame icon after 3+ consecutive correct answers
- [ ] Difficulty selector on start screen (for parents to choose level)
