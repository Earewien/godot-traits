[![Discord Banner](https://discordapp.com/api/guilds/1067685170397855754/widget.png?style=banner2)](https://discord.gg/SWg6vgcw3F)

# Godot Traits

Traits made easy in [Godot Engine](https://godotengine.org/).

![image](addons/godot-traits/documentation/assets/addon-icon.png)

## 📖 Godot Traits in a nutshell

Godot Traits is an addon taht aim to make traits available in GDScript. A _trait_ represents a set of behaviors (variables, functions, signals, ...) that can be use to extends the functionnalities of a class.

Since Godot Engine does not provide an _interface system_, many developers use composition to aggregate multiple behaviors in one class. But implementing composition the right way can quickly become messy and unconsistent. The aim of this addon is to provide a unified and easy way to add and remove behaviors to objects in Godot, by defining _trait_ classes, and attaching them to objects.

## 🗺️ Roadmap

- [x] Core trait system
- [ ] Automatic multi trait dependencies injection 
- [ ] Automatic dependent trait declaration and creation
- [ ] Generation of an helper script to provide strong typed features and code completion in editor

## 📄 Examples

Many usage examples are available in `addons/godot-traits/examples` folders. Each example has its proper `README` file explaining the example concept.

## 📄 Features

### Dynamic trait addition and removal

_Godot Traits_ allows to dynamically add or remove traits to any object at runtime. This allows to conditionnaly active some bahavior without having to maintain a state that must be accessible from anywhere. 

```gdscript
class_name Crate
extends Node2D

func _init() -> void:
    # Add Damageable trait to this crate
    # This allows to call take_damage on this crate damageable trait
    GTraits.add_trait_to(Damageable, self)

func make_understructible() -> void:
    # Removes the Damageable trait from this crate
    GTraits.remove_trait_from(Damageable, self)


class_name Game
extends Node2D

func _process_() -> void:
    var crate = get_node("crate)
    # Is always safe since we check if the trait is still available on the crate. No 
    # needs maintain an internal crate state saying it's invisible or not
    if GTraits.is_a(Damageable, crate):
        GTraits.as_a(Damageable, crate).take_damage(1)
```

### Strong runtime checks

We, as developers, often make strong assumptions on what we have as objects, for exemple, what kind of node we receive in a callback (_it's always a car !_ for example). But, how to be sure we receive what we intented to receive ? Most of callback methods just return `Node` type objects. Duck typing has some limitations when it comes to debugging your application (_if my object has the __kill__ method then call it, but what happens if it does not have the __kill__ method? No error !_).

_Godot Traits_ offers helpers to retrieve object traits with strong checks: if trait is not available, an assertion error is raised, and Godot ENgine debugger stopped at the erroneous frame.

```gdscript
class_name Crate
extends Node2D

func _init() -> void:
    # Create can take damage, but can not be moved !
    GTraits.add_trait_to(Damageable, self)

class_name Game
extends Node2D

func _process_() -> void:
    var crate = get_node("crate)
    # Move the crate only if it is moveable
    # This code does not throw assertion error since we check that the crate is moveable
    if GTraits.is_a(Moveable, crate):
        GTraits.as_a(Moveable, crate).move(Vector2.RIGHT)
    
    # This code will raise an assertion error since we asked for an unknown trait in the crate.If developer assumption is correct, it will always work, else GTraits will help the developer to undertand why its code is not working.
    GTraits.as_a(Moveable, crate).move(Vector2.RIGHT)
```

### Automatic trait dependencies injection

Traits may depends on each other to work, or may need a _receiver_ object (the trait carrier) to implement behavior. For example, a _Damageable_ trait surely needs a _Healthable_ object to remove health from when damage are taken. 

_Godot Traits_ offers automatic trait dependencies injection into trait constructors. 

If trait constructor asked for an object of the same type as the trait _receiver_ (or no type), then the receiver is automatically injected into the trait.

```gdscript
class_name Loggable

var context

# This trait needs a context to work (to log in chich context it has been called)
# Since there is no asked type, it will be the trait receiver
func _init(the_context) -> void:
    context = the_context

func log() -> void:
    # do something
    pass

class_name Crate
extends Node2D

func _init() -> void:
    # This will automatically make the crate to be the context of the Loggable trait that is beeing added
    GTraits.add_trait_to(Loggable, self)
    # So here, the assertion self == GTraits.as_a(Loggable, self).context is true !
```

If trait constructor asked for an object of another type as the _received_ type, then _Godot Traits_ will look into the _receiver_ to find a trait with that type, and inject it into the trait constructor.

```gdscript
class_name Contextualizable

var _receiver

# This trait needs an object to work. Since there is no asked type, it will be the trait receiver
func _init(receiver) -> void:
    _receiver = receiver

func get_context() -> void:
    return str(_receiver.get_instance_id())



class_name Loggable

var _context:Contextualizable

# This trait needs a Contextualizable to work. GTraits will automatically find
# that trait in the receiver object to inject it into this trait. If it can not be found, an assertion error will be raised.
func _init(context:Contextualizable) -> void:
    context = the_context

func log() -> void:
    print("Called in context %s" % _context.get_context())




class_name Crate
extends Node2D

func _init() -> void:
    # Add traits to the create. Order is important here, since Loggable trait needs
    # the Contextualizable trait to be construct. As a consequence, the trait Contextualizable must be available in the crate before trying to add the Loggable trait.
    GTraits.add_trait_to(Contextualizable, self)
    GTraits.add_trait_to(Loggable, self)
```

⚠️ For now, only constructor with zero or one argument are handled by _Godot Traits_. 

### Trait classes hierarchy

It's common to want to specialize some behavior using a sub-class. For example, specializing some code to handle critical damages: it's very like taking damage, but the amount of damage is not the same.

_Godot Traits_ handles this the right way: in a transparent way! If a trait has be specialized and added to an object, it can be seamlessly accessed throught its generic trait.

```gdscript
class_name Damageable

func take_damage(damage:float) -> void:
    var applied_damages:float = _compute_damages(damage)
    print("Damages : %s" % applied_damages)

func _compute_damages(initial_damage:float) -> float:
    return initial_damage





class_name CriticalDamageable
extends Damageable

func _compute_damages(initial_damage:float) -> float:
    return initial_damage * 2.5




class_name Crate
extends Node2D

func _init() -> void:
    # This crate will only takes critical damages !
    GTraits.add_trait_to(CriticalDamageable, self)




class_name Game
extends Node2D

func _ready_() -> void:
    var crate = get_node("crate")

    # We can access to the trait using it's real type, this will print 50 damages !
    GTraits.as_a(CriticalDamageable, crate).take_damage(25)
    # But we also can access to the trait using it's parent type, this will also print 50 damages since GTraits call the CriticalDamageable trait !
    GTraits.as_a(Damageable, crate).take_damage(25)
```