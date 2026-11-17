# Gaster — Secret Boss Preparation

Gaster is the project's **secret boss**. This document tracks the encounter foundation
without treating unconfirmed lore, mechanics, or balance values as canon.

## Implemented scaffold

- Dedicated `gaster_secret` enemy and Actor registry identities.
- Dedicated `gaster_secret` encounter entry point.
- Testing-room Gaster Fight Test station starts that encounter.
- Enemy CHECK text clearly labels its stats and mechanics as provisional.
- No attack wave is attached yet, so this is an encounter shell rather than a finished fight.
- Gaster currently uses the project's safe Kris sprite fallback until dedicated art is ready.

## Deliberately provisional

The current 6,666 HP / 30 ATK values are temporary scaffolding only. They are not
canonical values and should be replaced during balance design. No weapon-specific or
real-world attack replication is part of this plan.

## Design work still needed

1. Define the secret-boss discovery route and how the player earns access.
2. Decide the encounter's tone, dialogue voice, and how much Gaster communicates.
3. Define battle phases and their transitions.
4. Design abstract, readable SOUL hazards and clear telegraphs.
5. Decide the ACT / item / spare rules and how the fight resolves.
6. Create dedicated Gaster overworld and battle sprites, portrait, and effects.
7. Tune HP, damage, timing, and party interactions after the mechanics are playable.
8. Add automated tests for encounter loading, phase transitions, and resolution.

## Current test path

Use `testing-room_001` → **Gaster Fight Test**. This currently opens the scaffold
encounter; it is not yet a complete boss fight.
