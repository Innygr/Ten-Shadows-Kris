# Kristal Runtime Requirements

## Target build

The initial project manifest targets the installed engine reported for development:

- Kristal: v0.10.0-192-geaf9e0ef
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
└── docs/
    ├── KRISTAL_PORT_PARITY.md
    ├── KRISTAL_RUNTIME.md
    └── MULTIPLAYER_BASELINE.md
```

Kristal discovers encounter, enemy, and wave classes by their script folders and file IDs.
The initial manifest starts runtime_smoke_test, which adds runtime_dummy, which selects the
runtime_smoke wave. The test enemy reuses the engine's built-in Kris actor so this first
integration does not depend on custom sprite files.

## First launch checklist

1. Place the repository folder in the Kristal mods directory.
2. Launch the target Kristal build and select Ten Shadows Kris.
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
