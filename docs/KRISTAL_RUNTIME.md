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
integration does not depend on custom actor sprite files. It registers Inspect and Kris-only
Signal ACTs, preserves CHECK and the standard X-ACT response, and uses a custom visible
bullet for a short dodgeable attack. The test enemy also registers the party spell ACTs (RUSH, BRIGHTEN, HEAL, REVIVESONG,
ICE SHOCK, ICE WAVE, and TORNADO), Chimera Shadow Garden, and all ten Ten Shadows
summons with their TP costs. The five custom party definitions and seven custom spells
must live in the mod registry directories: `scripts/data/party/` and `scripts/data/spells/`.

## Automated checks and artifacts

The repository includes `.github/workflows/kristal-checks.yml`. GitHub Actions runs it on
pushes, pull requests, and manual dispatch. It currently:

- Parses `mod.json` and checks the required project fields.
- Rejects the incorrect `darkInventory` key.
- Runs Lua 5.1 syntax validation (`luac5.1 -p`) on every Lua file.\n- Executes `tests/flavor_text_test.lua` to check multiple variants, repeat avoidance, conditions, and fallbacks.
- Confirms the smoke-test encounter, enemy, wave, and custom bullet files exist.
- Checks that the runtime enemy registers party spells, all ten shadows, and Chimera Shadow Garden.
- Checks that the runtime enemy handles custom ACTs and the standard X-ACT.
- Checks that the smoke wave spawns the custom runtime-test bullet.
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
4. Confirm the placeholder enemy, battle UI, and ACT menu load.
5. Open Kris's ACT list and confirm all ten shadows plus Chimera Shadow Garden appear with their TP costs.
6. Confirm all five party members (Kris, Susie, Ralsei, Noelle, Berdly) load, and their spell menus expose the expected custom spells.
7. Use CHECK, Inspect, Kris's Signal ACT, and the standard X-ACT; confirm each returns dialogue.
8. Dodge the five slow bullets during the short attack wave, then confirm the wave exits cleanly.
9. Finish the encounter and confirm Kristal returns without a Lua error.
10. Record the exact engine build and any console traceback before changing the scaffold.

The repository work environment does not contain the user's Kristal/LÖVE runtime, so this
launch checklist remains unverified here. Do not mark runtime checks complete based only on
static inspection or successful GitHub commits.

## Current intentional limitations

- The manifest now selects all five party IDs. Kris, Susie, Ralsei, and Noelle use their
  matching built-in actors; Berdly currently uses Kris's actor as a temporary visual placeholder
  until dedicated Berdly battle/overworld art is added. The custom party data sets the project's
  intended HP and stats for all five members.
- The temporary test enemy is not the Knight + Titan. It exists only to prove the engine's
  mod -> encounter -> enemy -> wave loading path and ACT registration/dispatch.
- The first custom spell set now has real Kristal spell classes: Susie's RUSH and BRIGHTEN;
  Ralsei's HEAL and REVIVESONG; Noelle's ICE SHOCK and ICE WAVE; and Berdly's TORNADO.
  Damage, healing, revival, and the temporary defense buff are implemented in the shared
  runtime spell helper and covered by Lua tests. CHILL/freeze and Tornado disruption are
  currently recorded as target state flags; the real Knight + Titan turn scheduler still needs
  to consume those flags. The Ten Shadows ACT entries and Chimera Shadow Garden still need
  their actual summon/domain presentation and combat effects.
- The runtime smoke wave now fires five slow, visible test bullets. It is a basic attack/collision test, not a production boss pattern.
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


## Five-member party and first spell pass

The current manifest party is Kris, Susie, Ralsei, Noelle, and Berdly. Kristal v0.10.0's
registry loads custom PartyMember definitions from `scripts/data/party/` and custom Spell definitions
from `scripts/data/spells/`. Keep these paths inside the mod's `scripts/` tree. The first spell pass is:

| Character | Spell | TP | Current effect |
| --- | --- | ---: | --- |
| Susie | RUSH | 0 | 34 damage |
| Susie | BRIGHTEN | 4 | +1 temporary DEF to active party members |
| Ralsei | HEAL | 16 | Restore 22 HP to one ally |
| Ralsei | REVIVESONG | 84 | Revive at half HP, or heal half max HP |
| Noelle | ICE SHOCK | 16 | 18 damage; adds 1 CHILL |
| Noelle | ICE WAVE | 28 | 30 damage; adds 2 CHILL |
| Berdly | TORNADO | 20 | 16 damage; records next-attack disruption |

`tests/runtime_spells_test.lua` exercises the shared effects without needing the graphical
runtime. GitHub Actions also syntax-checks every Lua file and packages both artifacts. This is
still not a substitute for launching the project in Kristal: party menu visibility, target
selection, animations, spell action completion, and battle transitions must be checked in-game.

Kris's Ten Shadows remain registered as enemy ACTs for the current scaffold. The summon list
and domain rules exist in `scripts/ten_shadows/combat_state.lua`, but their runtime ACT
handlers are not yet connected to those rules. Berdly's actor is explicitly a placeholder;
his actual art is still outstanding.


## Party balance and equipment exclusions

The current mod-balanced stat profiles for the expanded test party are:

| Member | HP | ATK | DEF | MAG |
| --- | ---: | ---: | ---: | ---: |
| Kris | 240 | 17 | 2 | 0 |
| Susie | 290 | 24 | 2 | 2 |
| Ralsei | 210 | 10 | 2 | 9 |
| Noelle | 220 | 7 | 1 | 11 |
| Berdly | 240 | 20 | 2 | 8 |

The party now uses a late-game Chapter 6-7 fan-game HP scale, not official unreleased chapter data. Noelle's Chapter 2 baseline is 90 HP; her 220 HP profile is an extrapolation that places her near Ralsei and Kris while preserving her low physical defense and high magic. Kris, Susie, and Ralsei were raised to a coherent late-game baseline as well, using the lower end of their known Chapter 5 HP ranges as a reference. Berdly's 240/20/2/8 profile is original fan-game balance, positioned between Kris and Susie physically with moderate magic. The ThornRing is explicitly denylisted in CombatState.BLACKLISTED_EQUIPMENT; future equipment import and equip paths must check CombatState.isEquipmentBlacklisted(item_id). The current prototype does not yet implement a complete equipment UI or loader, so the denylist is in place as a rule for the upcoming equipment integration rather than a claim that a finished menu filter already exists. tests/combat_balance_test.lua covers the denylist and all five party HP baselines.


## Vessel SOUL-mode boss attack sets

The shared combat state now contains a scheduler-ready attack set for each Vessel mode: Red, Blue, Green, Yellow, Purple, Orange, and Cyan. Every mode has a distinct Knight move, a distinct Titan move, and a synchronized Knight + Titan move. Selecting a mode with state:setSoulMode("yellow") (replace yellow with the active mode) makes the scheduler alternate the mode-specific Titan and Knight attacks, with the combined move on the normal combo cadence. If the Knight is frozen, the Titan-specific move is still selected. Passing nil to setSoulMode returns to the original 37-entry attack scheduler.

Each attack definition exposes an ID, source, phase availability, pattern key, and short mechanic description. The pattern key is the contract for the future Kristal Wave implementation; these definitions do not yet create the visible bullet patterns. The actual shared Knight + Titan enemy and its Wave classes are still outstanding, so this pass is core scheduling/data logic, not an in-game playable SOUL-mode implementation. tests/soul_mode_attacks_test.lua checks all seven modes, attack-source alternation, combo timing, invalid-mode rejection, and frozen-Knight behaviour.
