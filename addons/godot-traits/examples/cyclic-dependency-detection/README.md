# Cyclic dependencies detection

This example demonstrates how cyclic dependencies are detected when instantiating traits.

Trait dependencies (constructor parameters) can be auto-instantiate. There exists a corner case where a cyclic
dependency can exist between required dependencies. As a consequence, it's not mpossible to create the object graph.
_Godot Traits_ can detect such cyclic dependencies and warn the developer about them.

## Technical elements

- `main.tscn` : scene to run. The main scene try to add `Cyclic1` trait, but this trait can not be instantiated due to
  cyclic depdencies. An assertion error will be raised.
