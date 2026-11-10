# Kristal Runtime Requirements

## Target build

The initial project manifest targets the installed engine reported for development:

- Installed Kristal build: v0.10.0-192-geaf9e0ef
- Manifest compatibility target: v0.10.0
- CI standalone archive engine: Kristal v0.10.0
- Runtime: LÖVE 11.5
- Project entry: mod.json
- Mod initialization: mod.lua

The manifest's engine version must be updated deliberately when the project moves to another
Kristal build. Do not silently target the latest engine API while the user's installed runtime
remains on a different version.

## Required project structure

```
Ten-Shadows-Kris/
├── mod.json
├── mod.lua
├── scripts/
│   ├── battle/
│   │   ├── encounters/
│   │   │   └── runtime_smoke_test.lua
│   │   ├── enemies/
│   │   │   └── runtime_dummy.lua
│   │   └── waves/
│   │       └── runtime_smoke.lua
│   ├── objects/
│   │   └── soul_ejection.lua
│   └── ten_shadows/
│       └── combat_state.lua
└── assets/
```

Kristal discovers encounter, enemy, and wave classes by their script folders and file IDs.
The initial manifest starts runtime_smoke_test, which adds runtime_dummy, which selects the
runtime_smoke wave. The test enemy reuses the engine's built-in Kris actor so this first
integration does not depend on custom sprite files.

## Automated checks and artifacts

The repository includes `.github/workflows/kristal-checks.yml`. GitHub Actions runs it on
pushes, pull requests, and manual dispatch. It currently:

- Parses `mod.json` and checks the required project fields.
- Rejects the incorrect `darkInventory` key.
- Runs Lua 5.1 syntax validation (`luac5.1 -p`) on every Lua file.
- Confirms the smoke-test entry-point files exist.
- Packages a clean Kristal mod folder as `Ten-Shadows-Kris-test.zip`.
- Checks out Kristal v0.10.0, integrates the mod as the target mod, and creates
  `Ten-Shadows-Kris.love` from the engine source.

The workflow publishes two separate artifacts:

- **Ten-Shadows-Kris-test** — the mod folder to install into an existing Kristal setup.
- **Ten-Shadows-Kris-love** — a standalone LÖVE archive containing the Kristal v0.10.0
  engine with Ten Shadows Kris integrated and configured to start automatically.

Download either artifact from the successful workflow run's **Actions → Artifacts** section.
The standalone `.love` archive requires LÖVE 11.5; it is not a platform-specific executable.
The test ZIP is intended for Kristal's normal project/mods location.

The packaging steps deliberately exclude the browser prototype (`*.html`, root-level
prototype JavaScript), Markdown documentation, and repository metadata from the game packages.
Those files remain useful in the source repository but are not runtime game content.

These checks catch malformed configuration and Lua syntax errors and verify archive structure.
They do **not** boot Kristal/LÖVE, load every asset, verify all engine API calls, or play through
the encounter. A green CI run is a build pass, not proof of an in-game test pass.

To run the static checks locally on Ubuntu/Debian, install `lua5.1` and `python3`, then run:

```sh
python3 -m json.tool mod.json >/dev/null
find . -type f -name '*.lua' -not -path './.git/*' -print0 |
  xargs -0 -n1 luac5.1 -p
```

## First launch checklist

1. Download the `Ten-Shadows-Kris-test` artifact and extract its project folder into
   Kristal's projects/mods location, or launch the standalone `.love` archive with LÖVE 11.5.
2. For the mod ZIP, launch the target Kristal build and select Ten Shadows Kris. For the
   standalone archive, the integrated mod should start automatically.
3. Create a new file. The manifest should route into the runtime smoke-test encounter.
4. Confirm the placeholder enemy and battle UI load.
5. Defend through the short test wave and confirm it exits cleanly.
6. Finish the encounter and confirm Kristal returns without a Lua error.
7. Record the exact engine build and any console traceback before changing the scaffold.

The repository work environment does not contain the user's Kristal/LÖVE runtime, so this
launch checklist remains unverified here. Do not mark runtime checks complete based only on
static inspection or successful GitHub commits.

## Current intentional limitations

- The initial test party is the engine-provided Kris, Susie, and Ralsei. Noelle and Berdly
  require their own Kristal party definitions, stats, actions, and visual assets before they
  can be placed in the manifest party list safely.
- The temporary test enemy is not the Knight + Titan. It exists only to prove the engine's
  mod -> encounter -> enemy -> wave loading path.
- The test wave is intentionally short and contains no custom projectile patterns.
- No overworld map is configured yet. The first milestone is a known-good battle runtime;
  the route map and story entry point follow once that is stable.
- No networking transport is present. Multiplayer requirements are defined separately in
  MULTIPLAYER_BASELINE.md and must not block offline startup.

## Runtime acceptance criteria

- [ ] Mod appears in the Kristal project selector.
- [ ] New file enters runtime_smoke_test.
- [ ] Enemy actor, dialogue, and battle UI load without missing assets.
- [ ] runtime_smoke wave starts and ends.
- [ ] Encounter can finish and return cleanly.
- [ ] No Lua traceback appears during startup, battle, or exit.
- [ ] A fresh save and a second launch both behave consistently.
