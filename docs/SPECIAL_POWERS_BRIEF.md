# Special powers: Great black-back and kittiwake

Handover brief, 2026-11-03, revised 2026-11-08 after a review against the code. Design agreed; Shakedown built (task 064), the rest not started.
Source plan: `docs/BRASHNESS_BACKLOG.md`. Both powers fire like Gang Call: full brashness meter, then Q or the touch power button.

**Perks are out of scope.** David will rethink them once the specials exist. Do not change, retire or migrate any perk in these tasks.

## Shared rules
- Each species' `power` block holds its id, display name, ready label (replaces the hard-coded "CALL!"), fire sound and meter fill rates.
- Screeching stays herring-only, so the other two earn more from their own play: black-backs from bumps and muggings, kittiwakes from direct snatches.
- `add()` stays blocked while a power is active.
- A power cannot fire while stunned.
- Level end and pause must leave a clean state: gull visible, `Engine.time_scale` restored, vendor back up, invulnerability cleared.

**Known gap until the perk rethink:** with Bullet Time equipped, Q never reaches `brash.fire()` and the HUD hides the brash meter, so these two species have no way to fire. Playtest the specials without that perk. Resolve it before release.

## Great black-back: SHAKEDOWN
**Fantasy:** the beach bully, exaggerated. Everyone flees and nothing can stop you.

1. **Untouchable.** Use the existing `invulnerable` timer, which already blocks stuns, rival muggings and boss bumps. Suppress its flicker during the power and emit `stun_ignored` when a stun is blocked. Leave `stun_shield` alone: it powers Strong Skull and must not be spent. Sand crashes still tumble the gull.
2. **Rolling panic.** Re-run `CrowdPanic.warn` and `stampede` around the gull about once a second, so the fear travels with you and clears buyers at a stall (`look_up` already cancels their orders).
3. **The shake.** Humans the gull touches, and rivals carrying food, drop it. This pays off when no stall is close.
4. **Counter raid.** Peck while grounded within a stall's width, or on its roof if that looks wrong in game. Each peck spits out a fresh food item, using the bin's spawn code.

- Duration about 8 s (tunable).
- Raid limits, tunable: a cap on food per raid, and a food list with no large items. At the 0.18 s peck cooldown, an uncapped raid would allow about 44 items.
- Vendor: ducks fully out of sight by moving down inside the existing serving-window mask. No new character art, within AGENTS.md. A ducked vendor ends any active order and refuses new ones until the power ends. Normal stall service and its dive-snatch bonus window are untouched afterwards.
- Not included: a rival-only version, or a one-peck jackpot.

## Kittiwake: LIGHTNING STRIKE
**Fantasy:** mark three foods, then become a lightning streak that takes all three.

1. **Windup.** Time slows and any food the aim cone sweeps over locks on with a numbered reticle (`assist_target`). Ends at 3 marks, at a timeout, or on a second press. Fewer than 3 marks still fires. No marks: refund the meter.
2. **Fizz.** The gull is hidden behind a lightning streak and auto-snatches each mark in order. A mark that has gone (eaten, stolen, portion withdrawn) is skipped with a small fizzle.
3. **Land.** After the last snatch the gull returns to normal shape, mid-air, with about 0.5 s of invulnerability.

- **Swallowed whole:** strike snatches skip the stomach and score immediately. The stomach holds 4 units and medium and large foods cost 2 and 4, so three foods would rarely fit otherwise.
- The windup uses its own real-clock timer and does not call `start_slowmo`/`end_slowmo`, which belong to Bullet Time. It must end cleanly on pause.
- The dash is its own state, not `STRIKE`, so a low target cannot trigger a sand crash. Award the counter bonus explicitly on stall portions.
- Control modes: realistic and normal lock on by aim. Casual and touch auto-mark the nearest 3.
- Not included: a no-cooldown free-flying mode, or a power that plays itself without aiming.
- **Prove it first:** build a rough version with no new FX and playtest it. The species is sold as "QUICK DIVER" and this replaces diving with a short automatic sequence. If it feels flat, Feeding Frenzy from the backlog is the cheap fallback.

## Code work
1. Extend the `power` block in `data/species.json` as above. Show the power's ready label on the meter.
2. In `scripts/brashness.gd`, add active-power state (`active_id`, `active_left`). `fire()` branches on `power.id`, and the Gang Call sound and crowd warning move into the Gang Call branch. `clear()` covers every new state.
3. Shakedown: power flag on `BeachGull`, rolling panic, drop on contact, counter-raid hook and vendor duck.
4. Lightning Strike: windup state, mark list and reticles, auto-dash through marks with gull hide/restore, Godot-drawn jagged bolt between marks.
5. Power-timer bar by the meter, results-board line, a `power_fired` analytics event.
6. Integration tests for each power (fire, effect applied, expires), plus: level end and pause mid-power, Strong Skull charge unspent during Shakedown, a lost mark, a full stomach during a strike.
7. Size: two Sonnet tasks, Shakedown first; Lightning Strike is larger.

## FX options (pixelfx, MIT, pinned commit `a841596`)
**Lightning Strike**
| Beat | Effect |
|---|---|
| Windup | `lightning/charge-up` |
| Gull enters the fizz | `arcane/blink-out` |
| Contact on each food | `lightning/zap-hit` |
| Gull returns | `arcane/blink-in` |
| Bolt line, reticles | Drawn in Godot, no pixelfx |

`lightning/chain-lightning` is a style reference only (fixed geometry).

**Shakedown**
| Beat | Effect |
|---|---|
| Active aura | `status/rage` |
| Stun blocked | `impacts/shield-block` |
| Fire shockwave | `impacts/ground-slam` (alt: `lightning/thunderclap`) |
| Counter landing, pecks | Existing `heavy-landing`, `hit-spark`, `crit-hit` |

**Risks (check by eye):**
- Glow effects need an outline to read on pale sand and sky, as `collect-burst` did.
- `rage` is drawn for a 24x38 humanoid and may not suit the smaller gull.
- Frames are large against the 320x180 canvas; each needs a `scale` in `data/sprites.json`.
- Always render with `--no-actor` (`assets/sprites/pixelfx/NOTICE.md`).

**Fallback:** if the sheets fail the look test, a Codex art task is still needed (aura loop, reticles, lightning streak).

## Next steps
1. Shakedown is built (task 064, existing effects only); playtest it.
2. Build a rough Lightning Strike and playtest. Keep it or switch to Feeding Frenzy.
3. With David's OK, clone pixelfx outside the repo, render the candidates still needed (`charge-up`, `blink-out`, `blink-in`, `zap-hit`, `rage`, `shield-block`, `ground-slam`) and review on a sand and sky background.
4. Trim and register the passing sheets (`tools/trim_pixelfx_sheet.py`, `data/sprites.json`); recipe in `assets/sprites/pixelfx/NOTICE.md`.
5. Rethink perks, including Bullet Time and the Q conflict.

## Open questions
- Shakedown duration, raid cap and panic interval; Lightning Strike windup length (tuning).
- Licence of the unlabelled Seagull sound pack, for the new fire stings.
