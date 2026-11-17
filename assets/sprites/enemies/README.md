# Enemy sprites

Enemy and boss sprite sheets. Keep each enemy's source art and runtime export together.

## Knight + Titan runtime actors

The battle enemies use separate Kristal Actor IDs:

- `roaring_knight` → future runtime sprite root: `assets/sprites/enemies/roaring_knight/`
- `roaring_knight_titan` → future runtime sprite root: `assets/sprites/enemies/roaring_knight_titan/`

The Actor definitions currently inherit Kris's valid dimensions, animation map, and sprite path
as a fallback. Their intended sprite roots are stored as
`ten_shadows_asset_path` in the respective Actor definitions. Do not switch the live
`Actor.path` until compatible files exist; a missing frame path can break sprite creation.

When importing original or otherwise authorized artwork, preserve the source pixel dimensions
and transparent background. Then map the available idle, attack, hurt, and other required
animations in the matching Actor definition, update its width/height and offsets, and set
`ten_shadows_sprite_ready = true` only after the complete runtime mapping is present.

## Static previews

The top-level `assets/sprites/manifest.json` is a separate preview/catalog manifest. It does
not register Kristal Actors or supply their runtime animations.
