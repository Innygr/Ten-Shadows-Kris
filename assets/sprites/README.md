# Sprite assets

All game sprite assets live under this directory. Keep source artwork separate from runtime-ready exports.

- `characters/` — Kris and party sprites, including future runtime-ready Berdly frames.
- `enemies/` — Knight and other enemy sprites.
- `shikigami/` — Ten Shadows summons.
- `effects/` — attacks, shadows, particles, and status effects.
- `ui/` — battle UI sprites and icons.

Use transparent PNGs for pixel art. Preserve native pixel dimensions and use nearest-neighbour scaling; do not smooth or resize source art. Keep licensing/source notes beside imported assets. The runtime currently has procedural fallback sprites; add actual PNGs here as they are prepared.

## Runtime sprite paths

`characters/` is the browser-preview/static image area. Kristal actors resolve runtime frames from `party/<actor path>/`; see [`party/README.md`](party/README.md) for Berdly's planned Light World and Dark World directories.
