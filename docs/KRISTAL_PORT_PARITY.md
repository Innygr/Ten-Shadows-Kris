# Kristal Port Parity — HTML Prototype

The browser build (`index.html` plus its JavaScript modules) is the feature reference.
The intended shipped implementation is the Kristal/Lua game. New gameplay work should
be made in Kristal first; HTML is a reference and regression checklist, not the target.

**Rule:** a feature is not considered ported merely because its data or a standalone helper
exists. It is complete only after it is connected to the Kristal encounter, works in-game,
and has been tested in Kristal.

## Current Kristal foundation

- `scripts/objects/soul_ejection.lua`: detached SOUL movement/drawing controller. Not yet
  connected to Kris's overworld controls, collapse/restore sequence, or character dialogue.
- `scripts/ten_shadows/combat_state.lua`: Lua-native party, TP, boss phase/status,
  summon, ACT/spell, domain, and encounter-scheduling rules. Not yet connected to a
  Kristal Encounter/Enemy/Wave/UI implementation.
- The repository currently has no committed `mod.json`, `mod.lua`, Kristal map, or
  registered battle encounter. The Lua modules are groundwork, not a runnable Kristal port.

## Feature parity checklist

### Battle flow and party

- [x] Core data: Kris, Susie, Ralsei, Noelle, Berdly; HP caps and role labels.
- [x] Core data: per-character basic attack damage.
- [x] Core rules: party member lookup, living-party filtering, action lists.
- [ ] Kristal integration: five-character battle party and correct turn order/death skipping.
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
- [ ] Kristal integration: all of these actions appear for the correct character, have correct target selection, costs, messages, and turn consumption.

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
- [ ] Port the flavor-text registry and its conditional selection.
- [ ] Port opening/battle flavor text and the Odd Radio / mayo armor entries where those items exist.
- [ ] Port sprite-sheet animation handling and sprite-asset manifest fallback behaviour.
- [ ] Port the battle scene composition: party lineup, Knight foreground, Titan looming behind,
  summon effects, and phase ambience using Kristal sprites/objects rather than HTML canvas.
- [ ] Port the bullet arena/SOUL visuals and all visual feedback (damage, invulnerability,
  guard, courage, status and phase indicators).
- [ ] Preserve the single-file aborted Weird Route premise: Chapter 2 enemies frozen except
  Berdly; only this file remains accessible; other files were destroyed by the Knight.

## Implementation order

1. Make the repository a valid Kristal mod and register the battle encounter.
2. Connect `combat_state.lua` to the Kristal Encounter, enemy, party actions, TP UI, and items.
3. Port the full Knight/Titan wave library, including all 37 attack definitions.
4. Integrate SOUL ejection into the overworld and then into the boss encounter.
5. Port route state, flavor text, sprites, and battle presentation.
6. Test every action, phase transition, attack, status, and win/loss path in the actual
   Kristal runtime. Only then mark the matching checklist entries complete.

This checklist intentionally distinguishes **Lua rules implemented** from **playable Kristal
features**. Do not mark an item complete until it is wired into Kristal and runtime-tested.
