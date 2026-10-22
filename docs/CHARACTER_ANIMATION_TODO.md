# Character animation to-do

- [ ] **Yell and curse after abandoning a snatch chase.** Shoppers (all three
  appearances) and pier diners should stop running, face the escaping gull and
  perform a short frustrated yell/curse gesture before resuming their routine.
  The gameplay already has a `give_up` phase (0.65 seconds); it currently uses
  existing angry artwork. Add expressive generated or user-supplied character
  frames, with optional comic curse symbols. Keep the complete source artwork,
  normal adult scale, matching feet and existing food anchors. No character
  bodies, faces or limbs may be drawn with code. This animation is deferred by
  user request on 20 October 2026.

  - [x] Original yellow-shirt shopper pilot authorized and implemented on 21
    October 2026: empty-hand surprise, unchanged bounded pursuit, and two planted
    harmless fist shakes before routine resume.
  - [x] Pier diner follow-up authorized and implemented on 21 October 2026 with
    the same timing and state flow, its own generated full-body reaction frames,
    and the existing diner run. The mullet shopper, older woman and remaining
    cast deliberately retain their prior behaviour/art pending review.

- [x] **Pier diner carrying walk improvement.** Replaced the sliding four-frame
  promenade with a generated six-phase contact/down/passing cycle, kept food on
  the separate steady serving-hand anchor, and matched fast-departure cadence to
  its three-times movement speed. The approved run, reactions, adult scale and
  other cast remain unchanged. See `docs/DINER_WALK_V2.md`.
