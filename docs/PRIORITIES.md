# Priorities to mid-December 2026

Set 5 November 2026 by David. These three themes come first until about 15 December. New work goes here first. Opus then turns it into task files in `tasks/inbox/`. Anything else waits unless it unblocks one of these themes or is a bug fix.

| # | Theme | Goal by mid-December |
|---|-------|----------------------|
| P1 | Controls | Touch, keyboard and mouse each playable with one hand position and no "which button?" moment. The separate PECK button is probably removed. |
| P2 | Level design | Levels feel different from each other. Small birds (sparrows or pigeons) compete for food, and a crumb lady creates contested hotspots. |
| P3 | VS and team VS | A basic VS sandbox (solo and team) whose score posts to a global Talo leaderboard. |

Rough timeline (6 weeks):

- **Weeks 1–2 (to 19 Nov):** P1 controls. The control scheme decides how P2's new birds are fought off and how VS is played.
- **Weeks 2–4 (to 3 Dec):** P2. Small-bird art goes to Codex in week 1 so it is ready in time.
- **Weeks 4–6 (to 15 Dec):** P3 sandbox and leaderboard. It reuses P2's crumb lady and small birds as sandbox content.

---

## P1 — Controls

### Where we are
- **Actions:** flap (hold; mouse left, Space, pad A, touch FLAP), dive (mouse right, Shift, pad B, touch DIVE), peck (E, pad X, touch PECK; holding it screeches) and a touch slow-motion button. Control modes from task 036: Realistic / Normal / Casual, where Casual already auto-pecks during a dive.
- **Touch:** a left stick plus four right-thumb buttons in a small cluster (`TOUCH_BUTTONS` in `scripts/input_controller.gd`). Aim assist for the stick came in task 018.
- **Mouse:** the cursor aims and the two buttons flap and dive, but peck and screech still need the E key. Mouse players need both hands and the keyboard.
- **Still open from player feedback F1:** `flight.coast_drag` is still 8, so the gull overshoots dives. The aim marker (suggestion 3) has not been built.

### Plan
1. **Decide on one action button (design, Opus + David).** Recommended: make Casual's auto-peck in dives the default, and fold ground peck and screech into a context button:
   - In a dive, pecking is automatic.
   - On the ground or a perch, tap DIVE/ACTION to peck (crabs, bins, stash raids).
   - Hold ACTION while airborne and not diving to screech (or hold FLAP + ACTION; test both).
   - Keep the timed peck as a **Realistic**-mode skill option, so the skill ceiling and the COUNTER bonus stay.
2. **Touch layout v2 (Sonnet).** Two big buttons (FLAP, ACTION) with bigger hit areas, plus the stick. Try swipe-down-to-dive as an option. Move slow motion off the thumb cluster. Test on a phone at real size (Playwright touch emulation plus a real device).
3. **Keyboard (Sonnet).** One-hand layouts: arrows + Z/X, and WASD + Space/Shift. Show only the active device's prompts (prompt detection was fixed on 25 Oct).
4. **Mouse (Sonnet).** Left = flap, right = dive/action with context peck, hold right = screech. No keyboard needed.
5. **Dive feel (data first).** Raise `coast_drag` to about 25–40 (feedback F1, suggestion 2) and add the faint aim marker on the target snack while a dive is possible (suggestion 3).
6. **Training Day and HUD copy.** Update the lessons, prompts and `training_text()` for the new scheme. Use the `dives` / `dive_pecks` / `dive_snatches` / `dive_overshoots` analytics to compare before and after.
7. **Tests.** Input regression checks per device, and the existing flight, dive and peck suites stay green.

**Done when:** a new player finishes Training Day on phone, keyboard-only and mouse-only without a peck button, and the analytics overshoot rate drops.

### Open decisions
- Does the PECK button go everywhere, or stay in Realistic only?
- Where does screech live (hold ACTION, or FLAP + ACTION)?
- Should Casual score less? (open since task 036)

---

## P2 — Level design and new animals

### Where we are
- Seven levels exist (`data/levels/level_01–07.json`). The stage plan in `docs/superpowers/specs/2026-10-22-levels-stages-quests-design.md` gives each level a twist: wind, Gary, the off-lead dog, Chip, the Bev boss. Crabs, the sweeper, water-gun teens, benches, squall and gang call are in.
- The October playnotes complaint ("levels all have the same population and set-up") was partly fixed by tasks 023, 027 and 034, but levels still share most of their cast.

### Plan
1. **Level identity pass (Opus spec).** One page per level giving its signature hazard, its signature food hotspot, its cast mix and its pacing (quiet start → rush → finale). Cut cast elements that don't serve the level.
2. **Small birds: sparrows and/or pigeons (Codex art, then Sonnet).**
   - Role: ground flocks that land on crumbs and dropped food and eat it fast, so they are a nuisance rather than a threat.
   - Fight them off: a landing or dive scatters the flock, a screech clears a radius (this gives screech a use outside the herring power), and pecking one makes the flock flee.
   - Small-bird flocks join the Spawner depth bands like other ground actors (AGENTS.md depth rule, with checks). Art follows the AGENTS.md character rules.
   - Pick one species first (pigeons read better at 320×180), then add sparrows as the fast, skittish variant.
3. **Crumb lady (Codex art, then Sonnet).** She walks to a bench or spot, sits, and throws crumbs in bursts. Pigeons gather and the player must clear them or out-eat them. Throwing makes her a predictable hotspot, and she shoos gulls (but not pigeons). This is a natural Level 2–4 twist and the bench system from task 026 already exists.
4. **Wire into levels.** Add pigeons and the crumb lady to two existing levels where they create a new decision, and add quest hooks ("Scatter 3 flocks", "Steal from the crumb lady").
5. **Review with the Art Lab** before the art is wired in (task 044 flow).

**Done when:** each level is described in one line that differs from the others, and pigeons and the crumb lady are playable in at least two levels with tests.

### Open decisions
- Pigeons, sparrows or both? Recommended: pigeons first.
- Does the crumb lady replace an existing cast member in her levels?

---

## P3 — VS mode, team VS and global leaderboard

### Where we are
- Rival AI gulls already compete for food and mug (tasks 011, 017, 038). There is a rival scoreboard (task 018) and gang-call ally gulls (task 040).
- Talo online high scores already work: one board per level, with player name entry (`scripts/autoload/online_scores.gd`, `data/talo.json`). The "online leaderboard" decision in `TODO.md` is settled.
- There is no human-vs-human multiplayer.

### Plan
1. **Pin down what "VS" means (David).** Recommended scope for December:
   - **VS (solo):** you against 3 AI rivals in a fixed-length round. The most food eaten wins.
   - **Team VS:** you plus 1–2 AI allies against a rival team. Team score is shared and team mugging rules apply.
   - Local 2-player (split keyboard and pad) is a stretch goal. Online real-time multiplayer is out of scope until 2027.
2. **Sandbox arena (Sonnet).** One compact arena layout built from existing parts: stalls, bins, crab spawns, the crumb lady and pigeons from P2. Use a fixed seed per week so leaderboard scores are comparable. Round length and difficulty live in data.
3. **Team logic (Sonnet).** Add a team id to `BeachGull`. Allies don't mug teammates, and the AI picks targets per team. Team scoreboard HUD.
4. **Leaderboard (Sonnet).** New Talo boards `vs-solo` and `vs-team` (and a weekly seed board if Talo's refresh options allow it). Reuse name entry. Add basic sanity checks (maximum plausible score per round) and a privacy line on the itch page.
5. **Menu entry.** VS tile on the title or level select, unlocked after Level 3 (or always open in the demo build, to be decided).

**Done when:** a VS round and a team VS round play end to end in the web build and post to their global boards.

### Open decisions
- VS against AI only, or local 2-player too?
- Is VS in the itch demo (`data/demo.json` is currently disabled)?

---

## Previous to-dos: what is still pending

Checked against `main` at `6a11ee3` on 5 Nov 2026.

### Done (can be struck from older lists)
- Online leaderboard: Talo boards plus name entry (`TODO.md`, parked 25 Oct). Done 30 Oct.
- Keyboard showing controller prompts (feedback F2) and dive analytics (suggestion 4). Done 25 Oct.
- October playnotes: rival panel position (018), dog chase range (024, 019), carry sprite (029, 031, 036-art), level variety (023), lane switching and bin depth (025), benches and wandering after theft (026), cast size and prop overlaps (027), grill and fish & chips art (028, 030).
- Codex to-do of 21 Oct (signs, vendor poses, crabs). Done 22 Oct.
- Stage 1 levels 1–6 and quests (002–016).

### Still pending, and how it relates to the priorities
| Item | Source | Status | Priority link |
|------|--------|--------|---------------|
| Coast slowdown (`coast_drag` still 8) | Feedback F1, suggestion 2 | Open | **P1** step 5 |
| Aim marker on the dive target | Suggestion 3 | Open (no marker in the code) | **P1** step 5 |
| Follow up with the player on how stealing feels | Suggestion 5 | Open | After P1 |
| Dive feel ("discuss later") | `TODO.md` | Open | **P1** |
| Casual scores less? | Task 036 | Open | **P1** decision |
| Sweeper tasks 037 and 038 | `tasks/done/` | Code on `main`, status still `done`, not yet reviewed or merged. 038 report lists 8 unrelated failing checks. | Housekeeping: review now |
| 049 small-art grid fixes | `tasks/done/` | Rejected; the sign work (050) is blocked on its item 9 | Art backlog |
| Pixel grid decision (2× grid) | `TODO.md`, art audit | Open | Art backlog (not a priority) |
| Codex art inbox: 039, 042, 046, 047, 051, 053, 054, 058, 059, 060, 061 | `tasks/inbox/` | 11 art tasks waiting | Lower than the P2 pigeon and crumb-lady art; queue those first |
| Sonnet inbox: 050 beach signs, 052 character text tags | `tasks/inbox/` | Waiting | 052 is small; 050 is blocked |
| Brashness juice and powers for the other species | `BRASHNESS_BACKLOG.md` | Nice to have | Parked; screech's new role in P2 may reuse parts |
| Stage 2 (Pier & Sea, levels 7–10) and the diving mechanic | Stage spec | Not started (`level_07` exists) | Parked until after December |
| Sound licence check for the seagull pack | `BRASHNESS_BACKLOG.md` | Open | Before the next public release |
| 8 failing checks (card 1, bin leftover scoring, level 5 dog, squall teleport, twelve foods, demo.json) | Task 038 report | Open | Fix before new P1 work lands |

### Next actions for Opus
1. Review the sweeper tasks 037 and 038 and triage the 8 failing checks.
2. Write P1 tasks: the control decision memo for David, then Sonnet tasks for touch v2, keyboard, mouse and coast drag + aim marker.
3. Write Codex art tasks for the pigeon flock and the crumb lady (full-body generated sprites, following the AGENTS.md rules).
