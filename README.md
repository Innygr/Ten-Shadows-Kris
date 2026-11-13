# Deltarune: Shadowbender

A Deltarune fangame prototype and Kristal project, officially titled **Deltarune: Shadowbender**.

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
- A new file now starts the Knight + Titan playtest encounter (`knight_titan_preview`), using
  the shared 260 HP boss, six-member party, and Knight + Titan assault Wave.
- `runtime_smoke_test.lua`, `runtime_dummy.lua`, and `runtime_smoke.lua` remain available as a
  separate engine-integration diagnostic path.
- `scripts/objects/soul_ejection.lua`: detached SOUL controller foundation.
- `scripts/ten_shadows/combat_state.lua`, `runtime_shadows.lua`, and `attack_wave_patterns.lua`:
  six-member party rules, boss ACT/status/SOUL-mode integration, disruption, and six reusable
  projectile-pattern families. Wall, aimed, and falling attacks now telegraph their paths before
  projectiles become dangerous. BRIGHTEN resolves as one grouped ACT and preserves queued
  Noelle, Berdly, and Vessel actions. Bespoke attack mechanics and final presentation remain in progress.

## Build artifacts

GitHub Actions publishes three artifacts after the checks pass:

- `Deltarune-Shadowbender-standalone-Love-11.5`: recommended. Download and extract this ZIP,
  then open the inner `Deltarune-Shadowbender.love` file with **LÖVE 11.5**. This is the complete
  game and includes the Kristal v0.10.0 engine plus `assets/fonts/main.ttf`.
- `Deltarune-Shadowbender-love-file`: the standalone `.love` file by itself. GitHub still wraps
  downloaded Actions artifacts in a ZIP, so extract the downloaded ZIP before opening the
  inner `.love` file.
- `Deltarune-Shadowbender-mod-only-Kristal-v0.10.0`: mod-only ZIP for an existing Kristal v0.10.0
  installation. **Do not open this ZIP or its extracted mod folder with LÖVE.** It does not
  contain the engine entry point or engine fonts.

**Important:** launch the inner `.love` file, not the downloaded artifact ZIP. The mod-only
package is only for installing into a working Kristal installation.
The HTML/JavaScript browser prototype and documentation are source/reference material; they are
not included in either game package.

A new file now enters the Knight + Titan playtest directly. The boss still uses Kris's built-in
actor as a temporary visual stand-in until dedicated Knight/Titan art is added, and the current
six-member turn flow, boss presentation, and battle transitions still need verification in a
local Kristal launch. The six project party members are Kris, Susie, Ralsei, Noelle, Berdly, and
Vessel. Berdly's actor also remains a temporary visual fallback.

## Startup troubleshooting

If startup reports `assets/fonts/main.ttf` is missing, first check which file was opened:
the standalone artifact must be extracted, and the inner `Deltarune-Shadowbender.love` file is the
one to launch. Opening the mod-only ZIP/folder is not a supported launch method. When using an
existing Kristal installation instead, its own `assets/fonts/main.ttf` engine asset must be
present; reinstall or repair that Kristal engine rather than copying the mod folder into LÖVE.

## Multiplayer

Multiplayer is part of the architecture baseline from the start, but is not implemented yet.
Single-player must remain fully playable offline. The host-authoritative session model and
transport boundary are documented before networking code is introduced.
