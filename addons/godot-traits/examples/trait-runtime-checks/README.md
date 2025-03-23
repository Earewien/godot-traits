# Traits runtime checks

This example demonstrates how traits are checked at runtime, to ensure everything is going as
it was imagined by the developer.

## Technical elements

- `main.tscn` : scene to run. The main scene instantiates a unique NPC, with some traits. When asking for
  a trait that does not belongs to the NPC, an assertion error is raised at runtime.
- `npc.gd` : a very simple NPC with some traits.
