# Kristal runtime party sprites

This directory is the runtime sprite root used by Kristal Actor paths.

For Berdly, the planned actor paths are:

- Dark World: `party/berdly/dark`
- Light World: `party/berdly/light`

Those paths resolve under `assets/sprites/`, so the corresponding directories are `assets/sprites/party/berdly/dark/` and `assets/sprites/party/berdly/light/`.

Keep the runtime images separate from `assets/sprites/characters/`, which is used by the project's sprite metadata/browser preview loader. The actor files still inherit Kris's paths until compatible Berdly art is ready; do not change the actor path while its expected PNG frames are missing.

For directional walking frames, follow Kristal's numbered-frame convention, for example `walk/down_1.png`, `walk/down_2.png`, and so on. Preserve native pixel dimensions, transparent backgrounds, and nearest-neighbour rendering. Add only original or otherwise authorized artwork.
