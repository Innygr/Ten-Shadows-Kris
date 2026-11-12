# Character sprites

Party character sprite sheets and individual character frames. Use transparent PNG, native pixel dimensions, and document frame rectangles/animation names in the asset manifest.

## Berdly

Berdly has a dedicated Kristal actor registry entry at `scripts/data/actors/berdly.lua`. Until runtime-ready frames are available, its animation definitions deliberately inherit Kris’s working set; this is a compatibility fallback, not finished Berdly artwork.

The Spriters Resource reference is a guide for identifying animation groups, not an asset bundled in this repository. Do not commit extracted copyrighted game sprites. For a final implementation, use original or otherwise authorized artwork, then record each animation’s frame rectangles, frame rate, origin, and loop behavior here and in the manifest.
