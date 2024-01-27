# Scene as a trait

This example demonstrates how traits can be simple scripts or complex scenes.

## Technical elements

- `main.tscn` : scene to run. The main scene instantiates add a `SelfDestructible` trait to an heart. This
trait is not a simple script trait, but it's a _Scene trait_! `Godot Traits` will automatically instantiate
the scene and use it as a trait. The instantiated trait will also be added to the receiver (the heart)
children, allowing complex behaviors.
