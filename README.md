# Ten Shadows Kris

A Deltarune fangame prototype and Kristal project.

## Engine priority

The **Kristal/Lua implementation is the target game**. The browser build (index.html) is a
feature reference and parity checklist; new gameplay systems should be implemented in Kristal
before changes to the JavaScript/HTML/CSS prototype.

See [Kristal Port Parity](docs/KRISTAL_PORT_PARITY.md) for the feature inventory and port status,
[Kristal Runtime Requirements](docs/KRISTAL_RUNTIME.md) for the engine entry point and smoke test,
and [Multiplayer Baseline](docs/MULTIPLAYER_BASELINE.md) for the networking architecture contract.

## Current Kristal foundation

- mod.json and mod.lua provide the initial Kristal project configuration and load hook.
- scripts/battle/encounters/runtime_smoke_test.lua, runtime_dummy.lua, and runtime_smoke.lua
  provide a minimal encounter/enemy/wave path for the first runtime check.
- scripts/objects/soul_ejection.lua: detached SOUL controller foundation.
- scripts/ten_shadows/combat_state.lua: Lua-native combat rules for the five-member party,
  TP, ACTs/spells, Ten Shadows, domains, shared Knight + Titan phases/statuses, and attack scheduling.

The initial runtime encounter is deliberately a placeholder, not the real Knight + Titan fight.
The manifest currently uses Kristal's built-in Kris/Susie/Ralsei party so it does not reference
unimplemented Noelle/Berdly character definitions. The five-member party remains a required
gameplay integration task.

## Multiplayer

Multiplayer is part of the architecture baseline from the start, but is not implemented yet.
Single-player must remain fully playable offline. The host-authoritative session model and
transport boundary are documented before networking code is introduced.
