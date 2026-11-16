# Kristal Port Parity — HTML Prototype

The browser build (index.html plus its JavaScript modules) is the feature reference.
The intended shipped implementation is the Kristal/Lua game. New gameplay work should
be made in Kristal first; HTML is a reference and regression checklist, not the target.

**Rule:** a feature is not considered ported merely because its data or a standalone helper
exists. It is complete only after it is connected to the Kristal encounter, works in-game,
and has been tested in Kristal.

## Current Kristal foundation

- mod.json and mod.lua now provide a project manifest and initialization hook.
- New files now start in `knight_titan_preview`: separate Titan (21,000 HP) and Knight
  (1,460 HP) enemies share the `knight_titan_assault` scheduler/Wave, not a health pool. The older runtime smoke-test
  encounter remains available as a separate engine diagnostic.
- scripts/objects/soul_ejection.lua: detached SOUL movement/drawing controller. Not yet
  connected to Kris's overworld controls, collapse/restore sequence, or character dialogue.
- scripts/ten_shadows/flavor_text.lua: Lua-native flavor text registry with multiple variants per key, conditional entries, fallback text, and repeat avoidance. It is wired into the Knight + Titan encounter's first-turn text, per-turn battle-box flavor, and identity-aware enemy dialogue. Phase conditions select the right line, and phase-transition announcements retain priority in both engine text channels. Story/route-state dialogue conditions are not wired yet.
- scripts/ten_shadows/combat_state.lua: Lua-native party, TP, Titan phase/status,
  summon, ACT/spell, domain, and encounter-scheduling rules. Knight and Titan use
  separate EnemyBattler HP pools while sharing the attack scheduler; player-action and
  full battle-UI integration are still incomplete.
- scripts/ten_shadows/boss_actions.lua: shared ACT dispatcher used by both EnemyBattlers.
  Ten Shadows, SOUL mode, BRIGHTEN, Domains, and V-ACT act on the currently selected boss,
  so the survivor keeps the same action set without sharing health.
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
- [x] Add the Knight + Titan encounter as two independent enemies: Titan (21,000 HP, 40 ATK, 800 DEF) and Knight (1,460 HP), both non-spareable and non-TIRED; Titan phase CHECK/dialogue transitions at 14,000 HP and 7,000 HP.
- [x] Make the Knight + Titan encounter the new-file starting encounter; keep the runtime smoke-test path as a separate diagnostic.
- [ ] Verify the new-file fight, party actions, wave lifecycle, victory/loss transitions, and asset loading in Kristal v0.10.0.
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
- [x] Kristal integration: when Kris is down, Susie, Ralsei, Noelle, and Berdly have their X-Action
  replaced by WAKE KRIS; Vessel receives WAKE KRIS in the ACT menu because Vessel has no X-Action slot.
- [ ] Kristal runtime: verify the downed animation clears, Kris returns at 1 HP, and the action is
  unavailable again once Kris is standing.
- [x] Kristal integration: first custom spell classes exist for RUSH, BRIGHTEN, HEAL, REVIVESONG, ICE SHOCK, ICE WAVE, and TORNADO, with costs and core effects covered by Lua tests.
- [ ] Kristal integration: verify spell menus, target selection, action completion, and battle turn consumption in Kristal.
- [x] Kristal integration: consume Knight disruption on the next Knight-led turn, diverting that slot to the Titan; preserve disruption while the Knight is frozen.
- [x] Kristal integration: connect CHILL stacks from Noelle's spells and Ten Shadows to the shared frozen-turn state; freeze exposes the boss for one enemy turn.

### Ten Shadows and domains

- [x] Core data: all ten summons and their original costs/effects are represented in Lua:
  Toad, Nue, Divine Dog, Great Serpent, Max Elephant, Rabbit Escape, Round Deer,
  Piercing Ox, Tiger Funeral, and Mahoraga.
- [x] Core rules: Chimera Shadow Garden costs 60 TP, can be used once, lasts 3 enemy turns,
  boosts summon damage by 1.35, and reduces summon costs to 75% (rounded up).
- [x] Kristal integration: Kris-only SHADOWS submenu dispatches into the runtime Ten Shadows effects, with the three-turn Mahoraga party-slot swap cleaned up on battle end.
- [ ] Kristal integration: custom summon animations/presentation and individual summon-specific Wave behaviours.
- [x] Kristal integration: Chimera Shadow Garden can be activated once from Kris's ACT menu; it reduces Ten Shadows costs and boosts summon damage. The domain lasts three enemy turns.
- [ ] Kristal integration: final Chimera visual presentation and dedicated end message.
- [x] Core rules: **Kris + Vessel fusion Domain Expansion** requires both characters standing, costs 60 TP, lasts three enemy turns, and consumes the same once-per-battle Domain use as Chimera Shadow Garden. Vessel supplies the barrier; Kris supplies the Ten Shadows environment.
- [x] Core rules: shadow-portal spell routing copies a spell descriptor, moves its launch point to a chosen exit portal, and preserves its original target. Portal entry/exit coordinates are arena-local inputs.
- [x] Core rules: Vessel's Granite Blast has a 100%-output attack descriptor whose origin can be selected anywhere inside the active fusion Domain.
- [x] Kristal ACT integration: Kris's ACT menu offers FUSION DOMAIN when Vessel is standing; otherwise it retains the ordinary CHIMERA SHADOW GARDEN option. Vessel has a V-ACT submenu with GRANITE BLAST (50 TP, 58 damage).
- [x] Kristal visual integration: the active fusion Domain now layers Vessel’s animated enclosing barrier and six barrier nodes over Kris’s shadow garden in the live assault Wave.
- [ ] Kristal runtime integration: connect the portal-routing descriptors to actual spell/projectile movement and add visible portal effects, target-position selection, and Granite Blast charge/launch presentation.

### Coordinated Knight + Titan encounter

- [x] Core data: separate Titan (21,000 HP, 40 ATK, 800 DEF) and Knight (1,460 HP) targets; both remain part of one coordinated fight.
- [x] Core rules: Titan-driven phase thresholds at 14,000 HP and 7,000 HP, advancing one phase at a time.
- [x] Core rules: exposed armour multiplies damage by 1.4.
- [x] Core rules: CHILL stacks to 3; at 3 it freezes the Knight for one enemy turn and exposes armour.
- [x] Core rules: frozen Knight does not attack; the Titan still attacks alone.
- [x] Core rules: Tornado disruption is preserved while the Knight is frozen and consumed by the next Knight-led attack.
- [x] Core rules: combined Knight + Titan attack cadence is every 4 turns in phases 1–2 and every 3 turns in phase 3.
- [x] Core data: all 37 attack IDs and phase/weight definitions from the HTML scheduler are represented in Lua.
- [x] Core rules: weighted attack selection, source alternation, Titan shield-class alternation,
  no immediate same attack when alternatives exist, and phase scheduler reset.
- [x] Core rules: Knight/Titan cannot become TIRED and cannot receive MERCY/SPARE.
- [x] Kristal CHECK integration: Titan and Knight each report live current HP and their own maximum HP.
- [x] Kristal ACT routing: both boss battlers delegate to the shared action handler; the Cyan Execution Counter is routed to the Knight and consumes a one-use 36-damage counter.
- [x] Automated regression: each EnemyBattler keeps its own HP; CHECK/Inspect reports live current/max HP; Titan armour exposure never boosts Knight damage; per-target exposure ticks for both bosses; Titan damage alone advances the shared phase scheduler; the survivor keeps attacking and retains Ten Shadows ACTs after the other is defeated.
- [x] Kristal UI contract: both enemies set `disable_mercy = true`, which the engine renders as a crossed-out Mercy bar.
- [ ] Kristal runtime: visually confirm both independent HP bars and survivor transitions in an actual playtest.
- [x] Kristal foundation: the selected attack now routes through six reusable projectile families (radial, safe-lane wall, aimed, crossfire, falling, and sweep), with separate Knight/Titan/combined projectile visuals and phase-scaled density.
- [ ] Kristal integration: all 37 attacks have a matching bespoke Kristal Wave, with the same phase access,
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

- [x] Core data: separate Knight, Titan, and combined attack definitions for the six non-default modes: Blue, Green, Yellow, Purple, Orange, and Cyan. Red uses the ordinary Knight/Titan attack library.
- [x] Core rules: selecting a Vessel mode switches the shared enemy scheduler to that mode's attack pool; Titan and Knight turns alternate, with a synchronized attack on the combo cadence.
- [x] Core rules: a frozen Knight still yields a Titan attack from the selected mode.
- [x] Kristal integration: Vessel's seven SOUL choices call state:setSoulMode(mode); choosing Red clears the special mode and restores the ordinary attack library.
- [x] Kristal foundation: all 30 non-default SOUL-mode attack definitions route through dedicated pattern-key geometry builders, with per-pattern telegraphs and mechanic markers.
- [x] Kristal projectile mechanic: Yellow SOUL Ricochet Blades telegraph four paths, then reflect from the arena bounds twice with a dedicated blade silhouette; the rebound path and limit are regression-tested.
- [ ] Kristal visuals/collision: finish the remaining SOUL-mode patterns' bespoke projectile presentation and any required mode-specific collision/guard/parry behaviour; most builders still establish distinct paths and telegraphs only.
- [ ] Kristal integration: implement bespoke mechanics for the 30 Blue, Green, Yellow, Purple, Orange, and Cyan Knight/Titan/combined Wave patterns using each definition's pattern key. The ordinary 37-attack library is the Red SOUL baseline, not a separate mode-specific attack set.
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
- [x] Connect flavor text selection to the Knight + Titan encounter's first-turn text, per-turn battle-box flavor, and enemy dialogue, including phase conditions and Vessel identity placeholders.
- [x] Port the opening and phase-aware Knight + Titan flavor lines.
- [ ] Connect flavor selection to Weird Route/story-state conditions and wire Odd Radio / mayo armor text to their in-game inspect actions when those objects are added.
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
4. Expand the shared Knight/Titan wave-pattern families into bespoke implementations for all 37 attacks.
5. Integrate SOUL ejection into the overworld and then into the boss encounter.
6. Port route state, flavor text, sprites, and battle presentation.
7. Test every action, phase transition, attack, status, and win/loss path in the actual
   Kristal runtime. Only then mark the matching checklist entries complete.

This checklist intentionally distinguishes **Lua rules implemented** from **playable Kristal
features**. Do not mark an item complete until it is wired into Kristal and runtime-tested.
