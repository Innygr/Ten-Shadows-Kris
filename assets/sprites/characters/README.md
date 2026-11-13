# Character sprite metadata and previews

This folder is for the project's browser-preview/static sprite metadata workflow. It is not Kristal's runtime Actor sprite root. Kristal actor images belong under `assets/sprites/party/<actor path>/`; Berdly's planned runtime folders are documented in [`../party/README.md`](../party/README.md). Use transparent PNG, native pixel dimensions, and document frame rectangles/animation names in the asset manifest.

## Berdly integration

Berdly now has separate Kristal actor registry entries for both world styles: `scripts/data/actors/berdly.lua` and `scripts/data/actors/berdly_lw.lua`. The playable party member binds the second with `setLightActor("berdly_lw")`, so Kristal's `Game:isLight()` actor selection can choose the right variant. They currently deep-copy Kris's Dark World and Light World actor configurations as compatibility fallbacks. Their nested animation, mirror, and offset tables are independent, so Berdly-specific overrides cannot mutate Kris's actor.

The Spriters Resource reference is a visual planning guide, not an asset bundled in this repository. It lists 23 Berdly animation groups. The core groups relevant to a playable party member include:

| Source group | Intended role |
| --- | --- |
| Berdly Walk Down (Dark World) | Overworld down movement |
| Berdly Walk Left (Dark World) | Overworld left movement |
| Berdly Walk Right (Dark World) | Overworld right movement |
| Berdly Walk Up (Dark World) | Overworld up movement |
| Berdly Battle Idle | Default battle stance |
| Berdly Battle Idle Right | Alternate battle-facing stance |
| Berdly Battle Idle Unhappy | Unhappy / damaged expression |
| Berdly Attack | Battle attack animation |
| Berdly Attack Unhappy | Alternate attack expression |
| Berdly Fly | Flight / special movement |
| Berdly Laugh | Expression / cutscene animation |
| Berdly Pointing Up | Expression / action animation |

The reference also has light-world and book-carrying walk variants, plus unused and scene-specific material. Those should be mapped only when the relevant scenes need them.

For the final implementation, use original or otherwise authorized runtime-ready artwork. Do not commit extracted copyrighted game sprites. Record each frame rectangle, frame rate, origin, and loop behavior here and in the manifest. The required battle states that are not represented by a matching source group will need original animation work or a carefully chosen non-animated fallback.

## Animation map

The 23 source animation-group names, their world variant, and their proposed Kristal roles are tracked in [`berdly/animation-map.json`](berdly/animation-map.json). Light World walk groups target `berdly_lw`; Dark World walk and battle groups target `berdly`. The file intentionally does not contain frame rectangles or sprite pixels: those must be recorded from original or otherwise authorized runtime-ready artwork, not guessed from a page thumbnail. CI validates the map's coverage and preserves the explicit `not-mapped` status until that work is completed.
