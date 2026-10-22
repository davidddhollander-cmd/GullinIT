# 001 — Anonymous gameplay analytics (PostHog)

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: none
Created: 2026-10-22

## Goal
Send a handful of anonymous gameplay events from the game (desktop and web) to PostHog, so we can see where demo players drop off: tutorial lessons, level starts/ends, first successful steal, feedback clicks. With no project key configured the game must send nothing and behave exactly as today.

## Context
- New autoload goes next to the existing ones in `project.godot` (`Config`, `GameState`, `Audio`).
- Hook points (verify line numbers, they drift):
  - `scripts/game.gd`: `dismiss_intro()` (level actually starts), `finish()` / `level_finished` signal (level end + result dict), `_training_advance()` (lesson completed), `_swallowed()` (first non-scrap snack eaten = first steal).
  - `scripts/main.gd`: the `"feedback"` action (FEEDBACK button clicked), `start_level()`.
  - `scripts/autoload/game_state.gd`: save file (`user://save.json`) — store the anonymous id and the opt-out flag here.
  - `scripts/menus.gd` `options()`: add the opt-out toggle next to SHAKE / TOUCH.
- Web build is single-threaded (`export_presets.cfg` → Web). `HTTPRequest` works on web; PostHog allows CORS from browsers.
- Respect CLAUDE.md: 8 px font grid for the new toggle; commit only files you changed.

## Requirements
1. **Config file** `data/analytics.json`:
   `{ "enabled": true, "host": "https://eu.i.posthog.com", "project_key": "" }`
   Empty `project_key` (or `enabled: false`) ⇒ no network requests at all. Keep it in the export include filter (`data/*.json` already covers it).
2. **Autoload** `scripts/autoload/analytics.gd` (name it `Analytics`) with `track(event: String, props: Dictionary = {})`:
   - POST JSON to PostHog's capture endpoint (`<host>/i/v0/e/`; confirm the current path in PostHog's docs) with `api_key`, `event`, `distinct_id`, `properties`, `timestamp`.
   - Add common properties to every event: `platform` (`web`/`windows`/other via `OS.has_feature`), `build` (a version string — add `config/version` to `project.godot` if missing, e.g. `0.1.0-demo`), `input` (`touch`/`gamepad`/`keyboard_mouse` from the game's input state when available), `$process_person_profile: false` (anonymous events only).
   - Fire-and-forget: a small queue, at most one request in flight, drop events after 2 failures; never block or stall gameplay; never print errors to the player.
   - Anonymous `distinct_id`: random 128-bit hex generated once and saved in `user://save.json`. No names, emails, IP-derived data or device identifiers.
3. **Opt-out:** Options menu toggle `STATS: ON/OFF` (default ON) saved with the other options; OFF ⇒ `track()` is a no-op.
4. **Events** (exact names):
   | Event | Properties |
   |---|---|
   | `session_start` | — (once per launch, after the title screen appears) |
   | `level_start` | `level`, `mode` (`arcade`/`practice`/`training`) |
   | `lesson_complete` | `lesson` (1–6), `seconds` since the lesson began |
   | `first_steal` | `level`, `seconds` since level start (once per run, non-scrap snacks only) |
   | `level_end` | `level`, `mode`, `score`, `stars`, `seconds`, `crashes`, `outcome` (`completed`/`failed`/`quit`) |
   | `feedback_click` | `screen` (`level_select`/`results`) |
   Track `quit` when the player leaves a running level via pause → LEVEL SELECT / restart.
5. **Tests** in a new `tests/analytics_checks.gd`, wired into `tests/integration.gd` `run()` like the other `preload(...).run(...)` checks. Do not make real network calls in tests — inject/override the sender. Cover: no key ⇒ nothing queued; opt-out ⇒ nothing queued; each event fires once with the listed properties at the right moment; distinct id persists across a save/load; queue drops after repeated failures without errors.
6. **Docs:** short section in README ("Analytics") listing the events, the opt-out and the config file. Add a one-line privacy note we can paste on the itch.io page.

## Out of scope
- No third-party SDK/plugin, no GDExtension (web build has no extension support).
- No changes to gameplay, tuning, art or level data.
- Do not add a real PostHog key — David will paste it into `data/analytics.json` later.

## Done when (acceptance)
- [ ] With empty `project_key`, a full playthrough makes zero HTTP requests (verified by test).
- [ ] With a dummy key and an injected fake sender, all six events are emitted with the specified properties.
- [ ] STATS toggle visible in Options, saved, and respected.
- [ ] Headless `tests/integration.tscn` passes with no new failures (one known Linux-only rounding failure "practice result distinguishes run time from saved best time" may remain).
- [ ] README updated; branch `sonnet/001-posthog-analytics` pushed; report filled in below.

## Report

## Review notes
