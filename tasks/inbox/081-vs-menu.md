# 081 — VS sub-menu

Status: inbox
Author: Claude
Assignee: Claude Sonnet
Depends on: 080
Created: 2026-11-11

## Goal
Players reach VS from the title screen through a sub-menu: mode list on the left (Match-up live, Ladder and Multiplayer as placeholders), arena and opponent selection on the right, then FIGHT!.

## Context
- Spec: `docs/superpowers/specs/2026-11-11-vs-mode-design.md`, sections "Flow" and "VS menu" (includes the layout sketch).
- Relevant files: `scripts/menus.gd` (`title`, `level_select`, `gull_picker`, `clear`, `_small_button`), `scripts/main.gd` (`_navigate`, the `casual` flag), `scripts/ui_factory.gd` (`BeachUI`), `data/vs.json`, `Config.arenas` (from task 080).
- Before writing code, use `godot-prompter:godot-ui` and `godot-prompter:godot-testing`.
- Constraints: 320x180 canvas; GullPixel at 8 or 16 px only; layout through containers like the other menus; keyboard/gamepad focus and touch must work as on the level select.

## Requirements
1. **Title:** replace the disabled `VS / COOP - LATER` button with an enabled `VS  >` button sending action `vs`.
2. **Flow:** `main.gd` gets a `vs` flag beside `casual`. `vs` sets it and opens the gull picker; picking a gull then opens the VS menu instead of the level select. `arcade` and `casual` clear the flag. The gull picker's back button returns to the title as today.
3. **`Menus.vs_menu()`**, titled `VS`:
   - **Left wood panel (about 96 px):** three buttons named `ModeMatchup`, `ModeLadder`, `ModeMultiplayer`. MATCH-UP is enabled and shown as selected. LADDER and MULTIPLAYER are disabled with a LATER caption.
   - **Right wood panel:** label `ARENA` and a row of toggle cards, one per `Config.arenas` entry (name in capitals); label `OPPONENT` and a row of toggle cards, one per `Config.vs.opponents` entry (name and `blurb`). One card per row is always selected; the first of each is preselected.
   - label `YOUR NAME` and a name field (reuse the result sign's name-entry rules: `OnlineScores.clean_name`, capitals and digits, `OnlineScores.NAME_LENGTH` = 8). It is prefilled with the saved player name, or with the default `HERRING` when none is saved ("HERRING GULL" does not fit the 8-character board name). The default lives in `data/vs.json` as `default_name`.
   - On FIGHT! the cleaned field text is saved with `OnlineScores.set_player_name`; an empty field saves the default. A VS round therefore always has a name, so the VS result sign never shows its `YOUR NAME?` prompt.
   - `< BACK` (to title) and `FIGHT!`, which sends `vs_start` with the selected `{arena, opponent}` and has focus when the menu opens.
4. **Result sign:** the second VS button from task 080 is captioned `VS MENU` and opens this menu.
5. Remove the temporary `vs` → title routing from task 080. Keep the `--vs` dev argument.
6. Selection screens stop the music like the other pickers.

## Out of scope
- Any Ladder or Multiplayer behaviour beyond the disabled buttons.
- Round rules, arena data, leaderboard (task 080).
- New art.

## Done when (acceptance)
- [ ] Title → VS → gull picker → VS menu → FIGHT! starts a Scrap Sands round against Gary
- [ ] MATCH-UP is enabled; LADDER and MULTIPLAYER are disabled
- [ ] Arena and opponent rows are built from data, with Scrap Sands and Gary preselected
- [ ] The name field shows the saved name or `HERRING`, saves on FIGHT!, and the VS result sign no longer asks for a name
- [ ] REMATCH and VS MENU work from the result sign; BACK returns to the title
- [ ] Arcade and Casual flows are unchanged (gull picker still leads to the level select)
- [ ] Checks added to `tests/vs_checks.gd`; any test that looked for `ComingSoonButton` is updated
- [ ] `./tools/validate.ps1` passes with no new failures

## Report
<!-- Filled in by the implementer: what changed (files), test results (check counts),
decisions/assumptions, anything not done, branch name and last commit hash. -->

## Review notes
<!-- Filled in by the reviewer. -->
