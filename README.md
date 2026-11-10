# Ten Shadows Kris

A Deltarune fangame prototype and Kristal project.

## Engine priority

The **Kristal/Lua implementation is the target game**. The browser build (`index.html`) is a
feature reference and parity checklist; new gameplay systems should be implemented in Kristal
before changes to the JavaScript/HTML/CSS prototype.

See [Kristal Port Parity](docs/KRISTAL_PORT_PARITY.md) for the complete feature inventory,
what has been ported into Lua, what is not yet connected to Kristal, and the implementation order.

## Current Kristal groundwork

- `scripts/objects/soul_ejection.lua`: detached SOUL controller foundation.
- `scripts/ten_shadows/combat_state.lua`: Lua-native combat rules for the five-member party,
  TP, ACTs/spells, Ten Shadows, domains, shared Knight + Titan phases/statuses, and attack scheduling.

These modules are not yet a complete playable Kristal encounter. Runtime integration and testing
are required before their features can be considered finished.
