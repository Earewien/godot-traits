# Use traits auto-injection system

This example demonstrates how traits auto-injection works. When defining a trait, its
`_init` can require the trait owner or another trait as dependency. It will be automatically
handled by `GTraits` system, or fail if something is not possible (cyclic dependency, missing trait, ...)

## Technical elements

- `main.tscn` : scene to run. The main scene instantiates a unique NPC, apply damages to him. It automatically
  dies when it runs out of health.
- `npc.gd` : a very simple NPC that as the `GTraitsCoreExampleKillable`, GTraitsCoreExampleHealthable` 
and GTraitsCoreExampleDamageable` traits. Since each trait depends to the previous one, trait order
  declaration in NPC is important !
