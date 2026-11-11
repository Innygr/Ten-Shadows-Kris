# Ten Shadows Kris

A Deltarune fangame prototype and Kristal project.

## Engine priority

The **Kristal/Lua implementation is the target game**. The browser build (index.html) is a
feature reference and parity checklist; new gameplay systems should be implemented in Kristal
before changes to the JavaScript/HTML/CSS prototype.

See [Kristal Port Parity](docs/KRISTAL_PORT_PARITY.md) for the feature inventory and port status,
[Kristal Runtime Requirements](docs/KRISTAL_RUNTIME.md) for the engine entry point, build artifacts,
and smoke test, and [Multiplayer Baseline](docs/MULTIPLAYER_BASELINE.md) for the networking
architecture contract.

## Current Kristal foundation

- mod.json and mod.lua provide the initial Kristal project configuration and load hook.
- scripts/battle/encounters/runtime_smoke_test.lua, runtime_dummy.lua, and runtime_smoke.lua
  provide a minimal encounter/enemy/wave path for the first runtime check.
- scripts/objects/soul_ejection.lua: detached SOUL controller foundation.
- scripts/ten_shadows/combat_state.lua: Lua-native combat rules for the six-member party,
  TP, ACTs/spells, Ten Shadows, domains, shared Knight + Titan phases/statuses, and attack scheduling.

## Build artifacts

GitHub Actions publishes three clearly separated artifacts after the checks pass:

- `Ten-Shadows-Kris-standalone`: recommended download. A ZIP containing the complete
  `Ten-Shadows-Kris.love` game archive plus launch instructions. Open the `.love` file with
  **LÖVE 11.5**. It includes the Kristal v0.10.0 engine and its required assets, including
  `assets/fonts/main.ttf`.
- `Ten-Shadows-Kris-love`: the raw standalone `.love` archive, also requiring LÖVE 11.5.
- `Ten-Shadows-Kris-mod`: mod-only ZIP for installation inside an existing Kristal v0.10.0
  installation. **Do not launch this ZIP or its extracted folder directly**; it does not contain
  the engine entry point or engine fonts.

The HTML/JavaScript browser prototype and documentation are source/reference material; they are
not included in either game package.

The initial runtime encounter is deliberately a placeholder, not the real Knight + Titan fight.
The manifest includes all six project party members: Kris, Susie, Ralsei, Noelle, Berdly, and Vessel.
Their in-game visibility and turn flow still need verification in a local Kristal launch. The current Berdly actor uses Kris as a temporary visual
fallback until dedicated art is added.

## Multiplayer

Multiplayer is part of the architecture baseline from the start, but is not implemented yet.
Single-player must remain fully playable offline. The host-authoritative session model and
transport boundary are documented before networking code is introduced.
