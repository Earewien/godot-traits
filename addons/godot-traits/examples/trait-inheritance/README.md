# Use trait inheritance

This example demonstrates how traits inheritance is handled. a NPC can take critical damages. This trait
is an extension of the damage trait.

## Technical elements

- `main.tscn` : scene to run. The main scene instantiates a unique NPC, apply damages to him. Applying damages
through critical damage or damage trait has the same effect : the critical damage trait is called.
- `npc.gd` : a very simple NPC that as the `GTraitsCoreExampleKillable`, GTraitsCoreExampleHealthable`
and GTraitsCoreExampleCriticalDamageable` traits.
