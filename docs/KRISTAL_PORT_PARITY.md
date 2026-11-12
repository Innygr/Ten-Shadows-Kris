# Kristal Port Parity — HTML Prototype

The browser build (index.html plus its JavaScript modules) is the feature reference.
The intended shipped implementation is the Kristal/Lua game. New gameplay work should
be made in Kristal first; HTML is a reference and regression checklist, not the target.

**Rule:** a feature is not considered ported merely because its data or a standalone helper
exists. It is complete only after it is connected to the Kristal encounter, works in-game,
and has been tested in Kristal.

## Current Kristal foundation

- mod.json and mod.lua now provide a project manifest and initialization hook.
- scripts/battle/encounters/runtime_smoke_test.lua, runtime_dummy.lua, and runtime_smoke.lua
  provide a minimal boot-to-battle smoke-test path. This is not the real boss encounter.
- scripts/objects/soul_ejection.lua: detached SOUL movement/drawing controller. Not yet
  connected to Kris's overworld controls, collapse/restore sequence, or character dialogue.
- scripts/ten_shadows/flavor_text.lua: Lua-native flavor text registry with multiple variants per key, conditional entries, fallback text, and repeat avoidance. Registry logic is tested independently; battle dialogue is not wired to it yet.
- scripts/ten_shadows/combat_state.lua: Lua-native party, TP, boss phase/status,
  summon, ACT/spell, domain, and encounter-scheduling rules. Not yet connected to the
  Kristal Encounter/Enemy/Wave/UI implementation.
- The manifest selects six party IDs: Kris, Susie, Ralsei, Noelle, Berdly, and Vessel.
  Their PartyMember definitions are in `scripts/data/party/`;
  custom spells are in `scripts/data/spells/`. Noelle uses the built-in Noelle actor; Berdly currently
  uses a temporary Kris actor placeholder. Vessel has a dedicated gray/red-outline actor based on Kris. Custom Knight/Titan boss sprite assets are not committed yet.
- A smoke-test scaffold is not considered runtime-verified until it has been launched with the
  project's target Kristal build.

## Runtime checklist

- [x] Kristal project manifest with project ID, engine version, chapter, initial encounter, and party.
- [x] Mod initialization hook.
- [x] Encounter registration path, enemy class, and a short no-projectile test wave.
- [ ] Launch the project in Kristal v0.10.0-192-geaf9e0ef and confirm all six party members appear in the battle.
- [ ] Confirm the six-member test wave ends cleanly and the battle can return to the menu without errors.
- [ ] Replace the temporary encounter with the shared Knight + Titan enemy and real battle flow.
- [x] Add custom PartyMember definitions for all six party IDs in `scripts/data/party/` and set the manifest party roster.
- [ ] Add dedicated Berdly and Knight/Titan sprites, then verify Kris → Susie → Ralsei → Noelle → Berdly → Vessel turn order and downed-member handling in Kristal.
- [ ] Add a real overworld start/map and route progression after the battle runtime is stable.

## Feature parity checklist

### Battle flow and party

- [x] Core data: Kris, Susie, Ralsei, Noelle, Berdly, and Vessel; HP caps and role labels.
- [x] Core data: per-character basic attack damage.
- [x] Core rules: party member lookup, living-party filtering, action lists.
- [x] Kristal foundation: six-member battle roster, battler creation, and paged action/overworld party selectors.
- [ ] Kristal runtime: verify all six members' turn order and downed-member skipping in-game.
- [ ] Kristal integration: FIGHT / ACT / ITEM / DEFEND / SPARE menu flow.
- [ ] Kristal integration: party HUD, HP bars, turn labels, dialogue, and battle-state feedback.
- [ ] Kristal integration: win/loss flow, retry behaviour, and encounter cleanup.

### TP, items, healing, and ACTs

- [x] Core rules: TP starts at 35, caps at 100, can be spent and gained.
- [x] Core rules: DEFEND grants 14 TP and marks the actor guarded.
- [x] Core rules: Dark Candy inventory starts at 3; each use restores 18 HP.
- [x] Core rules: Ralsei HEAL costs 16 TP and restores 22 HP to one living target.
- [x] Core rules: REVIVESONG costs 84 TP; revives a fallen target at half HP or heals a living target by half its maximum HP.
- [x] Core rules: CHECK gives 8 TP when the Knight is not exposed.
- [x] Core rules: DISTRACT exposes the Knight for 2 turns and grants 12 TP.
- [x] Core rules: Susie's RUSH deals 34 damage.
- [x] Core rules: Noelle's ICE SHOCK costs 16 TP, deals 18 damage, and adds 1 CHILL.
- [x] Core rules: Noelle's ICE WAVE costs 28 TP, deals 30 damage, and adds 2 CHILL.
- [x] Core rules: Berdly's TORNADO costs 20 TP, deals 16 damage, and disrupts the Knight's next attack.
- [x] Core rules: every non-Kris party member receives WAKE KRIS in their ACT list.
- [x] Core rules: WAKE KRIS restores Kris at 1 HP if Kris is down.
- [x] Kristal integration: first custom spell classes exist for RUSH, BRIGHTEN, HEAL, REVIVESONG, ICE SHOCK, ICE WAVE, and TORNADO, with costs and core effects covered by Lua tests.
- [ ] Kristal integration: verify spell menus, target selection, action completion, and battle turn consumption in Kristal.
- [ ] Kristal integration: consume CHILL/frozen and disruption flags in the Knight + Titan enemy-turn scheduler.

### Ten Shadows and domains

- [x] Core data: all ten summons and their original costs/effects are represented in Lua:
  Toad, Nue, Divine Dog, Great Serpent, Max Elephant, Rabbit Escape, Round Deer,
  Piercing Ox, Tiger Funeral, and Mahoraga.
- [x] Core rules: Chimera Shadow Garden costs 60 TP, can be used once, lasts 3 enemy turns,
  boosts summon damage by 1.35, and reduces summon costs to 75% (rounded up).
- [ ] Kristal integration: Kris-only SHADOWS submenu, summon descriptions, TP costs,
  summon presentation, and each summon effect.
- [ ] Kristal integration: Chimera Shadow Garden presentation, duration ticks, and end message.

### Knight + Titan shared encounter

- [x] Core data: one 260 HP shared boss target; Knight and Titan are one continuous fight.
- [x] Core rules: phase thresholds at 175 HP and 78 HP, advancing one phase at a time.
- [x] Core rules: exposed armour multiplies damage by 1.4.
- [x] Core rules: CHILL stacks to 3; at 3 it freezes the Knight for one enemy turn and exposes armour.
- [x] Core rules: frozen Knight does not attack; the Titan still attacks alone.
- [x] Core rules: Tornado disruption is preserved while the Knight is frozen and consumed by the next Knight-led attack.
- [x] Core rules: combined Knight + Titan attack cadence is every 4 turns in phases 1–2 and every 3 turns in phase 3.
- [x] Core data: all 37 attack IDs and phase/weight definitions from the HTML scheduler are represented in Lua.
- [x] Core rules: weighted attack selection, source alternation, Titan shield-class alternation,
  no immediate same attack when alternatives exist, and phase scheduler reset.
- [x] Core rules: Knight/Titan cannot become TIRED and cannot receive MERCY/SPARE.
- [ ] Kristal integration: actual shared enemy health/phase transitions and crossed-out Mercy UI.
- [ ] Kristal integration: all 37 attacks have a matching Kristal Wave, with the same phase access,
  timing, movement, hit rules, and difficulty variations.
- [ ] Kristal integration: Titan swarm/centipedes and purification/courage pickups.
- [ ] Kristal integration: Titan hands, closing gap, finger purification, and hand shots.
- [ ] Kristal integration: Titan Big Shots I/II/III and Desperation barrage/laser.
- [ ] Kristal integration: Knight Twin Slashes, Knight Combo, Sanguine Slash I/II,
  crystal barrage variations, revolver, and the remaining sword/star patterns.
- [ ] Kristal integration: Knight Domain Expansion — Kingdom of the Roaring — with falling stars
  and swords layered over the selected attack.
- [ ] Kristal integration: combined Titan + Knight collision attack.

### Vessel SOUL-mode boss attacks

- [x] Core data: separate Knight, Titan, and combined attack definitions for Red, Blue, Green, Yellow, Purple, Orange, and Cyan SOUL modes.
- [x] Core rules: selecting a Vessel mode switches the shared enemy scheduler to that mode's attack pool; Titan and Knight turns alternate, with a synchronized attack on the combo cadence.
- [x] Core rules: a frozen Knight still yields a Titan attack from the selected mode.
- [ ] Kristal integration: connect Vessel mode changes to state:setSoulMode(mode).
- [ ] Kristal integration: implement the 21 unique mode-specific Knight/Titan/combined Wave patterns using each definition's pattern key.
- [ ] Kristal integration: playtest each SOUL mode and verify arena movement, hitboxes, timing, and difficulty scaling in the actual Kristal runtime.

### SOUL control and ejection

- [x] Foundation: independent detached SOUL controller with directional movement,
  optional bounds, confirm callback, cancel/return callback, and procedural red-SOUL drawing.
- [ ] Kristal integration: eject from Kris in the overworld and suspend Kris's normal movement.
- [ ] Kristal integration: Kris collapses while detached and gets back up when the SOUL returns.
- [ ] Kristal integration: SOUL can talk/interact with characters; non-Kris characters react
  with confusion, with Ralsei's reaction handled separately if specified.
- [ ] Kristal integration: context-dependent Kris behaviour while the SOUL is out; do not
  force Kris to be universally scripted or universally independent.
- [ ] Kristal integration: SOUL deployment during the Knight + Titan fight.
- [ ] Kristal integration: any attempt to control/possess the Knight remains an explicit
  mechanic to implement only when its rules are defined; do not assume it succeeds.

### Route state, dialogue, visuals, and assets

- [ ] Port the Weird Route: Ice counters/flags/history without inventing route activation conditions.
- [x] Port the flavor-text registry to Lua, including multiple variants per key, conditional selection, fallback text, and avoiding an immediate repeat when alternatives exist.
- [ ] Connect flavor text selection to Kristal battle dialogue and story-state conditions.
- [ ] Port opening/battle flavor text and the Odd Radio / mayo armor entries where those items exist.
- [ ] Port sprite-sheet animation handling and sprite-asset manifest fallback behaviour.
- [ ] Port the battle scene composition: party lineup, Knight foreground, Titan looming behind,
  summon effects, and phase ambience using Kristal sprites/objects rather than HTML canvas.
- [ ] Port the bullet arena/SOUL visuals and all visual feedback (damage, invulnerability,
  guard, courage, status and phase indicators).
- [ ] Preserve the single-file aborted Weird Route premise: Chapter 2 enemies frozen except
  Berdly; only this file remains accessible; other files were destroyed by the Knight.

## Implementation order

1. Launch and verify the new runtime smoke test in the target Kristal build.
2. Replace the placeholder enemy with the shared Knight + Titan encounter while keeping the
   project launchable at every step.
3. Connect the combat-state rules to Kristal party actions, TP UI, items, enemy state, and waves.
4. Port the full Knight/Titan wave library, including all 37 attack definitions.
5. Integrate SOUL ejection into the overworld and then into the boss encounter.
6. Port route state, flavor text, sprites, and battle presentation.
7. Test every action, phase transition, attack, status, and win/loss path in the actual
   Kristal runtime. Only then mark the matching checklist entries complete.

This checklist intentionally distinguishes **Lua rules implemented** from **playable Kristal
features**. Do not mark an item complete until it is wired into Kristal and runtime-tested.
