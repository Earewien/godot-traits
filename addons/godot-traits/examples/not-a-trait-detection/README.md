# Detecting usage of types that are not traits

This example demonstrates how _Godot Traits_ detect usage of normal types (not traits) as traits.

## Technical elements

- `main.tscn` : scene to run. The main scene try to declare the node as a `NotATrait`, which is not
a trait type. This will raise an assertion error.
