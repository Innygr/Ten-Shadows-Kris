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

The standalone build leaves Kristal's optional native window icon disabled in `conf.lua`.
The icon asset is still packaged, but LÖVE no longer tries to load it as part of its earliest
boot configuration before the game initializes.

## Required project structure

```
Deltarune-Shadowbender/
├── mod.json
├── mod.lua
├── scripts/
│   ├── battle/
│   │   ├── encounters/
│   │   │   ├── knight_titan_preview.lua
│   │   │   └── runtime_smoke_test.lua
│   │   ├── enemies/
│   │   │   ├── roaring_knight_titan.lua
│   │   │   └── runtime_dummy.lua
│   │   └── waves/
│   │       ├── knight_titan_assault.lua
│   │       └── runtime_smoke.lua
│   ├── objects/
│   │   └── soul_ejection.lua
│   └── ten_shadows/
│       └── combat_state.lua
└── assets/
```

Kristal discovers encounter, enemy, and wave classes by their script folders and file IDs.
On a new file, Kristal reads the manifest's `encounter` option and starts that encounter after
loading the configured map. The manifest now selects `knight_titan_preview`, which creates the
shared Roaring Knight + Titan enemy and its `knight_titan_assault` Wave. The boss uses the
engine's built-in Kris actor as a temporary art placeholder; it does not require custom
Knight/Titan sprite assets to load. The separate `runtime_smoke_test` encounter remains useful
for diagnosing the engine's basic mod -> encounter -> enemy -> wave path.

The smoke-test enemy registers Inspect and Kris-only Signal ACTs, preserves CHECK and standard
X-ACT, and uses a custom visible bullet for a short dodgeable attack. The Knight + Titan fight
has its own Kris Ten Shadows submenu, Vessel SOUL-mode menu, phase state, and boss-specific
wave scheduler. The six custom party definitions and seven custom spells live in
`scripts/data/party/` and `scripts/data/spells/`.

## Automated checks and artifacts

The repository includes `.github/workflows/kristal-checks.yml`. GitHub Actions runs it on
pushes, pull requests, and manual dispatch. It currently:

- Parses `mod.json` and checks the required project fields.
- Rejects the incorrect `darkInventory` key.
- Runs Lua 5.1 syntax validation (`luac5.1 -p`) on every Lua file.
- Executes `tests/flavor_text_test.lua` to check multiple variants, repeat avoidance, conditions, and fallbacks.
- Confirms the smoke-test encounter, enemy, wave, and custom bullet files exist.
- Checks that the runtime enemy registers party spells, all ten shadows, and Chimera Shadow Garden.
- Checks that the runtime enemy handles custom ACTs and the standard X-ACT.
- Checks that the smoke wave spawns the custom runtime-test bullet.
- Packages a clean Kristal mod folder as `Deltarune-Shadowbender-mod.zip`.
- Checks out Kristal v0.10.0, integrates the mod as the target mod, and creates
  `Deltarune-Shadowbender.love` from the engine source.

The workflow publishes three clearly named artifacts:

- **Deltarune-Shadowbender-standalone-Love-11.5** — recommended. A downloadable ZIP containing
  `Deltarune-Shadowbender.love` and launch instructions. Extract the ZIP and launch the inner
  `.love` file with LÖVE 11.5.
- **Deltarune-Shadowbender-love-file** — the standalone `.love` file alone. GitHub wraps the
  downloaded Actions artifact in a ZIP; extract it before launching the inner file.
- **Deltarune-Shadowbender-mod-only-Kristal-v0.10.0** — mod-only package for an existing Kristal
  installation. It is not a runnable LÖVE game.

The standalone build includes the engine's `assets/fonts/main.ttf`. CI now extracts that
font from the generated `.love` archive and checks that it is non-empty and has a plausible
file size, in addition to checking that the archive contains the expected path.
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

## Preview boss ACT integration

The Knight + Titan preview enemy dispatches the Kris Ten Shadows submenu into the runtime
summon effects, connects all seven Vessel SOUL-mode choices to the shared scheduler, and
exposes Chimera Shadow Garden as a once-per-battle Kris ACT. BRIGHTEN remains a 4 TP grouped
ACT for Kris, Susie, and Ralsei; it applies the DEF buff directly and returns ACT dialogue
instead of injecting a second SPELL action into Kristal's action queue. The regression test invokes the real boss `onAct` handler with queued Noelle,
Berdly, and Vessel actions, then verifies those action records remain untouched. It also
checks that exactly the three participants are buffed and that a blocked use applies no buff.
The boss-bound CHILL and disruption effects update the shared boss state, so freezing the Knight
leaves the Titan's attack active and disrupting the Knight diverts its next action slot to the
Titan. Mahoraga is restored to Kris's party slot when the preview encounter ends.

This is the first pass of action/state integration, not final balance or visual polish. The
preview encounter is now the manifest's new-file starting encounter so the fight can be
playtested directly. The actions still need a hands-on Kristal v0.10.0 launch/playtest.

## Knight + Titan wave implementation

The preview encounter now uses a shared, deterministic spawn planner at
`scripts/ten_shadows/attack_wave_patterns.lua`. The selected scheduler entry is routed
through six reusable attack families: radial bursts, safe-lane walls, aimed volleys,
combined crossfire, falling shots, and horizontal sweeps. Projectiles are drawn with
separate Knight (red), Titan (cyan), and combined (gold) styling. Wall lanes, aimed
trajectories, falling columns, and the Knight-domain blades now show directional warning
lines before they become damaging projectiles. A warning has no hitbox and remains still;
the bullet gains its collider and configured speed only when the short tell expires.
Phase three increases pattern density, and an active Knight domain layers two additional
telegraphed falling blades over the selected pattern.

Tornado disruption is consumed on the next Knight-led scheduler slot. The Knight's action
is diverted to a Titan-only attack instead of disappearing; disruption remains pending
while the Knight is frozen. Status/domain durations tick once when the complete Wave ends,
not after each projectile volley.

These are shared pattern families rather than 37 bespoke recreations. Cyan mode now creates
a Cyan-coloured Soul that charges while confirm is held, then releases an expanding purge
that removes active projectiles. The dedicated Knight's Execution volley carries a parry
marker; a charged release near its armed slash staggers the Knight, exposes the shared boss,
grants 12 TP, and unlocks a one-use Kris EXECUTION COUNTER ACT for 36 damage. A mistimed or
undercharged release still purges the screen but does not grant the counter. Lua tests cover
the pattern marker, the real projectile class, Soul input/charge behaviour, purge, parry,
counter expiry, and encounter Soul factory. The Knight + Titan preview is now the manifest default to make the current
fight available immediately; the runtime smoke-test encounter remains selectable for
engine diagnostics. Dedicated Knight/Titan art is still outstanding.

## First launch checklist

1. For the standalone route, download and extract `Deltarune-Shadowbender-standalone-Love-11.5`,
   then launch the inner `Deltarune-Shadowbender.love` file with LÖVE 11.5.
2. For the mod-only route, install `Deltarune-Shadowbender-mod-only-Kristal-v0.10.0` into an
   existing Kristal v0.10.0 installation, then launch Kristal and select Deltarune: Shadowbender.
   Never open the mod-only ZIP or folder directly with LÖVE.
3. Create a new file. The manifest should route directly into `knight_titan_preview`.
4. Confirm the shared 260 HP Knight + Titan enemy, battle UI, and initial dialogue load.
5. Confirm all six party members appear and can select actions; inspect the paged action UI.
6. Open Kris's ACT list and confirm the Ten Shadows submenu and Chimera Shadow Garden appear.
7. Open Vessel's ACT list and select a SOUL mode; confirm the arena Soul's colour and type match.
8. Switch to a different mode and verify its special attacks do not run while another Soul type is active.
9. Select CYAN SOUL; hold confirm to charge, then release to purge the visible bullets.
10. In Phase 2 or 3, time a charged release near Knight's Execution to stagger the Knight and unlock Kris's EXECUTION COUNTER.
11. Use BRIGHTEN while Noelle, Berdly, and Vessel have actions queued; confirm their actions still resolve after the grouped ACT.
12. Dodge the six-volley Knight + Titan assault, then confirm the wave exits cleanly and the next turn starts.
13. Exercise CHECK/Inspect, summons, domain duration, CHILL, and Knight disruption.
14. Finish or lose the encounter and confirm Kristal returns without a Lua error. Record the exact engine build and any traceback.

The repository work environment does not contain the user's Kristal/LÖVE runtime, so this
launch checklist remains unverified here. Do not mark runtime checks complete based only on
static inspection or successful GitHub commits.

## Missing main.ttf troubleshooting

The `Could not open file assets/fonts/main.ttf` error occurs before the mod's battle code runs.
For the standalone route, make sure the downloaded Actions artifact ZIP was extracted and that
the inner `Deltarune-Shadowbender.love` file—not the outer ZIP—was opened. For the mod-only route,
check that the existing Kristal installation contains `assets/fonts/main.ttf`; that font is
an engine asset, not a file supplied by the mod folder.

## Current intentional limitations

- The manifest selects all six party IDs. Kris, Susie, Ralsei, and Noelle use their matching
  built-in actors. Vessel has a dedicated gray/red-outline actor; Berdly has a dedicated actor
  identity, but still borrows Kris's animation frames and portrait assets as visual placeholders.
- The temporary test enemy is not the manifest target. It remains available as a separate
  diagnostic for the engine's mod -> encounter -> enemy -> wave loading path and basic ACT dispatch.
- The first custom spell set now has real Kristal spell classes: Susie's RUSH and BRIGHTEN;
  Ralsei's HEAL and REVIVESONG; Noelle's ICE SHOCK and ICE WAVE; and Berdly's TORNADO.
  Damage, healing, revival, and the temporary defense buff are implemented in the shared
  runtime spell helper and covered by Lua tests. Boss-bound CHILL and disruption now update
  the shared scheduler: freezing suppresses the Knight for one turn while the Titan still attacks,
  and a disrupted Knight's next action slot is diverted to the Titan. Ten Shadows, the seven
  Vessel SOUL-mode choices, BRIGHTEN, and Chimera Shadow Garden now dispatch through the preview
  boss ACT handler. Dedicated summon/domain presentation and bespoke attack mechanics remain.
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


## Six-member party and first spell pass

The manifest and runtime roster now include Kris, Susie, Ralsei, Noelle, Berdly, and Vessel. Kristal v0.10.0 loads custom PartyMember definitions from `scripts/data/party/` and custom Spell definitions from `scripts/data/spells/`; keep these paths inside the mod's `scripts/` tree. Kris and Vessel have ACT access, Berdly has the custom B-Action, and Susie, Ralsei, Noelle, and Berdly have spell lists. The table below records the initial custom spell effects; it is not an exhaustive list of every spell currently registered.

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
runtime. GitHub Actions also syntax-checks every Lua file and publishes all three build artifacts. This is
still not a substitute for launching the project in Kristal: party menu visibility, target
selection, animations, spell action completion, and battle transitions must be checked in-game.

Kris's Ten Shadows remain registered as enemy ACTs for the current scaffold. The summon list
and domain rules exist in `scripts/ten_shadows/combat_state.lua`, but their runtime ACT
handlers are not yet connected to those rules. Berdly's actor is explicitly a placeholder;
his actual art is still outstanding.


## Party balance and equipment exclusions

The current mod-balanced stat profiles for all six party members are:

| Member | HP | ATK | DEF | MAG |
| --- | ---: | ---: | ---: | ---: |
| Kris | 290 | 17 | 2 | 10 |
| Susie | 350 | 24 | 2 | 2 |
| Ralsei | 250 | 10 | 2 | 14 |
| Noelle | 260 | 7 | 1 | 11 |
| Berdly | 310 | 20 | 2 | 8 |
| Vessel | 240 | 12 | 2 | 0 |

The party uses custom late-game fan-game stat profiles for all six members; these are original balance choices, not official unreleased chapter data. The values are designed around each member's intended role, with Susie as the physical heavy hitter, Ralsei as the primary magic support, and Noelle and Berdly providing additional spell options. Vessel has a balanced physical profile. The ThornRing is explicitly denylisted in CombatState.BLACKLISTED_EQUIPMENT; future equipment import and equip paths must check CombatState.isEquipmentBlacklisted(item_id). The current prototype does not yet implement a complete equipment UI or loader, so the denylist is in place as a rule for the upcoming equipment integration rather than a claim that a finished menu filter already exists. tests/combat_balance_test.lua covers the denylist and verifies all six active party members and their HP profiles.


## Vessel SOUL-mode boss attack sets

The shared combat state now contains a scheduler-ready attack set for each Vessel mode: Red, Blue, Green, Yellow, Purple, Orange, and Cyan. Every mode has a distinct Knight move, a distinct Titan move, and a synchronized Knight + Titan move. Selecting a mode with state:setSoulMode("yellow") (replace yellow with the active mode) makes the scheduler alternate the mode-specific Titan and Knight attacks, with the combined move on the normal combo cadence. If the Knight is frozen, the Titan-specific move is still selected. Passing nil to setSoulMode returns to the original 37-entry attack scheduler.

Each attack definition exposes an ID, source, phase availability, pattern key, and short mechanic description. The pattern key is the contract for the future Kristal Wave implementation; these definitions do not yet create the visible bullet patterns. The actual shared Knight + Titan enemy and its Wave classes are still outstanding, so this pass is core scheduling/data logic, not an in-game playable SOUL-mode implementation. tests/soul_mode_attacks_test.lua checks all seven modes, attack-source alternation, combo timing, invalid-mode rejection, and frozen-Knight behaviour.


## SOUL-mode attack gating

SOUL-mode attack definitions are only eligible when the active arena Soul carries the same
`ten_shadows_mode` as the Vessel's selected mode. The preview encounter creates a matching
colour-coded Soul, and the Wave passes the live Soul tag to the scheduler. A missing or
mismatched tag always falls back to the standard Knight/Titan attack pool; a mode selected in
the menu by itself cannot trigger another type's attacks.
