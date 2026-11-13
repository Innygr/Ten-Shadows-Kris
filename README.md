# Deltarune: Shadowbender

[![Kristal project checks and builds](https://github.com/Innygr/Ten-Shadows-Kris/actions/workflows/kristal-checks.yml/badge.svg)](https://github.com/Innygr/Ten-Shadows-Kris/actions/workflows/kristal-checks.yml)

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
  Noelle, Berdly, and Vessel actions. Cyan SOUL charges and purges bullets on release; a timed
  Knight's Execution parry staggers the Knight and opens a one-use Kris counter ACT. SOUL-mode
  attack sets only run while the matching coloured SOUL is active.

## Build artifacts

GitHub Actions publishes three artifacts after the checks pass:

- `Deltarune-Shadowbender-standalone-Love-11.5`: recommended. Download and extract the
  GitHub Actions artifact; it contains `Deltarune-Shadowbender-standalone.zip`. Extract that
  second ZIP, then open `Deltarune-Shadowbender.love` with **LÖVE 11.5**. This is the complete
  game and includes Kristal v0.10.0, the engine source, and `assets/fonts/main.ttf`.
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


### Troubleshooting: `src.engine.music` not found

The standalone archive must contain `src/engine/music.lua` at its root. The CI build checks
that exact path before publishing. Run the inner `.love` file from the standalone bundle with
LÖVE 11.5; do not launch `main.lua` from a partial source folder or open the mod-only package.
If the same error appears with the freshly downloaded standalone file, verify it with:

```bash
unzip -l Deltarune-Shadowbender.love | grep 'src/engine/music.lua'
```

The result should show exactly `src/engine/music.lua`. A missing result means the wrong or
incomplete archive is being launched.

## Vessel identity

On a new save, the game offers a Vessel identity setup screen. The name, gender,
pronouns, and visual presentation are saved independently of the Deltarune save.
The optional import reads the Vessel name from line 2 of a detected Deltarune
text save; it never edits that save. Existing saves can edit these values in
**Settings → Vessel Identity**. Dialogue/flavor text can use
`{vessel_name}`, `{vessel_subject}`, `{vessel_object}`,
`{vessel_determiner}`, `{vessel_possessive}`, and
`{vessel_reflexive}` placeholders.
