# Party Sprite Integration Plan

This document records the remaining sprite work without guessing frame rectangles,
animation timing, or offsets before the finished transparent PNGs are available.

## Berdly

- Actor identity: `berdly`.
- Planned runtime path: `party/berdly`.
- Current runtime state: independent actor configuration with a deep-copied Kris fallback.
- Existing reference map: `assets/sprites/characters/berdly/animation-map.json`.
- Next integration: map the Dark World walk directions, battle idle, battle attack,
  and any needed expression/action frames from the completed sprite sheets.

Do not add guessed frame rectangles to the existing map. It already records the source
animation groups while keeping the frame data explicitly unmapped.

## Vessel — Granite Blast

- Actor identity: `vessel`.
- Current actor presentation: private Kris configuration, grayscale shader, and
  the existing 1.15x vertical scale.
- Current Granite Blast visual: `scripts/battle/objects/granite_blast.lua`.
  It draws the charge, portal rings, beam, and impact at runtime; it does not yet
  consume sprite textures.
- Planned visual layers:
  1. Charge / gathering frames at the launch point.
  2. A portal-ring sequence for the entry and exit points.
  3. A tiling beam segment or short beam strip.
  4. A compact impact animation.

The Granite Blast object's visual must remain presentation-only. Damage is applied
once by the V-ACT handler, not by individual animation frames.

## Mahoraga

- Party identity: `mahoraga`, replacing Kris in Kris's battle slot until the encounter ends.
- Actor identity: `mahoraga`, with the dedicated future asset path recorded as
  `party/mahoraga`.
- Current runtime state: the independent actor uses Kris's known-good sprite frames
  as a fallback. The party portrait, head icon, and name sprite also remain on
  existing valid paths until dedicated art is installed.
- Existing gameplay settings: 999 HP and white party UI text/color.
- Planned art:
  - Head/menu icon.
  - Battle idle.
  - Battle transition / entrance.
  - Battle attack.
  - Battle hurt and downed states.

The separate actor registration means future Mahoraga frames can be mapped without
editing Kris's actor or changing the rest-of-battle replacement logic.

## Asset handoff rules

- Keep sprite backgrounds transparent.
- Use consistent frame dimensions within each animation strip.
- Provide the actual sheet dimensions, frame count, frame order, and desired
  frame duration when the art is ready.
- Record actor offsets from the real rendered frames; do not infer crop rectangles
  or alignment from a concept preview.
- Use original or otherwise authorized artwork for runtime assets.
