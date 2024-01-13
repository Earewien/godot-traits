[![Discord Banner](https://discordapp.com/api/guilds/1067685170397855754/widget.png?style=banner2)](https://discord.gg/SWg6vgcw3F)

# Godot Traits

Traits made easy in [Godot Engine](https://godotengine.org/).

![image](addons/godot-traits/documentation/assets/addon-icon.png)

## 📖 Godot Traits in a nutshell

Godot Traits is an addon designed to bring traits into GDScript. A _trait_ embodies a collection of behaviors (variables, functions, signals, etc.) that can be utilized to extend the functionalities of a class.

Given that Godot Engine lacks an official interface system, many developers resort to composition for combining various behaviors in a single class. However, implementing composition correctly can become complex and inconsistent. This addon's goal is to offer a streamlined and accessible approach for adding and removing behaviors from objects in Godot. This is achieved by defining trait classes and attaching them to objects, and using auto-generated utilities to use them.

## 🗺️ Roadmap

- [x] Core trait system
- [ ] Automatic multi trait dependencies injection 
- [ ] Automatic dependent trait declaration and creation
- [x] Generation of an helper script to provide strong typed features and code completion in editor
- [ ] Inline traits into scripts by using the `@inline_trait(TheTraitName)` annotation

## 📄 Examples

Many usage examples are available in `addons/godot-traits/examples` folders. Each example has its proper `README` file explaining the example concept.

## 📄 Features

### ➡️ In-editor features

#### 🔑 Trait declaration using annotation

_Godot Traits_ enables the definition of traits using the powerful class system of Godot Engine. Consequently, traits can encompass variables, functions, signals, call static functions, and more!

To distinguish your classes containing game logic from traits, _Godot Traits_ employs an annotation-like system. Given that it's not feasible to create new annotations in GDScript, _Godot Traits_ annotations are established within comments, as illustrated below:

```gdscript
# @annotation
# @annotation(param1=value1,param2=value2)
```

Declaring a trait is an exceptionally straightforward task:
```gdscript
#####
# File damageable.gd
#####

# @trait
class_name Damageable
extends Node

func take_damage(damage:int) -> void:
    pass
```

_And voilà !_ Your first trait is created. Traits can any class, regardless of the level of class nesting. This includes both the _top-level_ class (declared using the `class_name` keyword) and any _nested_ class (declared using the `class` keyword).

The higher the nesting level, the lengthier the trait invocation statement becomes, as invoking a trait necessitates unique identification of the class throughout all levels. To circumvent this issue, it's possible to declare an alias for the trait, such as a brief name, making it more convenient for use in the code.

```gdscript
#####
# File traits.gd
#####

class_name Traits

class SomeClass:

    # @trait
    class Damageable:
        pass

    # @trait(alias=Killable)
    class Killable:
        pass

# Damageable trait will be usable through Traits.SomeClass.Damageable reference
# Killable trait will be usable through Killable reference due to alias declaration
```

##### 📜 Trait declaration rules

- the `@trait` annotation comment must immediately precede the class declaration to be valid,
- annotations parameters must be declared between parenthesis, right after the `@trait` annotation. Parameters are separated by the `,` character, and parameter key and value are separated by the `=` character,
- if a script declares traits in _nested_ classes without declaring a _top level_ class, those traits will only be available in this script since those classes can be considered as _private_. The auto-generated class helper will not generate helper methods for those traits as they are _private_. See ___Auto-generated trait helper class to manipulate traits___ paragraph for more details.

#### 🔑 Auto-generated trait helper class to manipulate traits

_Godot Traits_ includes a code generation tool that offers helper methods for declaring and utilizing traits. This tool actively monitors trait declarations and modifications, automatically generating a `GDScript` file named `gtraits.gd` in a configurable folder.

Through this utility script, manipulating traits becomes easy and straightforward. It comprises four generic helper methods and four specific helper methods for each declared trait. For a trait named `Damageable`, the four methods are as follows:
- `set_damageable(object:Object) -> Damageable`: Applies the specified trait to make an object _Damageable_,
- `is_damageable(object:Object) -> bool`: Checks if an object possesses the _Damageable_ trait,
- `as_damageable(object:Object) -> Damageable`: Retrieves the _Damageable_ trait from the given object. This raises an error (in the form of a failed assertion) if the object _is not Damageable_,
- `unset_damageable(object:Object) -> void`: removes the _Damageable_ trait from the object.

```gdscript
#####
# File damageable.gd
#####

# @trait
class_name Damageable

func take_damage(damage:int) -> void:
    pass

#####
# File world.gd
#####
extends Node2D

func _ready() -> void:
    var crate:Node2D = preload("crate.gd")
    add_child(crate)
    crate.on_hit.connect(_on_crate_hit)

func _on_crate_hit() -> void:
    var crate:Node2D = get_node("crate")
    # GTraits class contains damageable helpers since Godot Traits has automatically found the Damageable trait.
    if GTraits.is_damageable(crate):
        GTraits.as_damageable(crate).take_damage(10)
```

_Godot Traits_ generation tool can also generate helper methods for _nested_ trait classes. As _nested_ class names may not be unique across the project and to prevent generating the same helper method twice, the generation tool utilizes the trait's _parent classes_ as context to create a unique helper name.

```gdscript
#####
# File traits.gd
#####

class_name Traits

class SomeClass:

    # @trait
    class Damageable:
        pass

# @trait
class Killable:
    pass

# Will automatically generates helpers methods:
# set_traits_some_class_damageable, is_traits_some_class_damageable, as_traits_some_class_damageable, unset_traits_some_class_damageable
# set_traits_killable, is_traits_killable, as_traits_killable, unset_traits_killable
```

_Godot Traits_ generation tool honors the _alias_ trait annotation parameter by creating helper methods named according to the specified alias.

```gdscript
#####
# File damageable.gd
#####

# @trait
class_name Damageable

func take_damage(damage:int) -> void:
    print("Take %s damages!" % _compute_damage(damage))

func _compute_damage(initial_damage:int) -> int:
    return initial_damage

# @trait(alias=CriticalDamageable)
class CriticalDamageable extends Damageable:
    func _compute_damage(initial_damage:int) -> int:
        return initial_damage * 2

# Will automatically generates helpers methods:
# set_critical_damageable, is_critical_damageable, as_critical_damageable, unset_critical_damageable
# instead of creating helpers methods:
# set_damageable_critical_damageable, ...
```

##### 📜 Auto-generated trait helper rules

- The generated `GTraits` script file can be safely committed to your _Version Control System_ (VCS),
- It is highly recommended not to make modifications in the generated `GTraits` script file, as these changes will be overwritten the next time the script is generated,
- _Godot Traits_ Code generation is customizable: its settings can be accessed through the _Editor > Editor Settings_ menu, under _GTraits_ section:
  - The _GTraits Helper Path_ represents the folder path where the `GTraits` script will be generated,
  - The _GTraits Helper Shortcut_ is a key combination that triggers a complete regeneration of the `GTraits` script by scanning all resources from `res://` folder.

![image](addons/godot-traits/documentation/assets/gtraits_settings.png)

- Nothing can prevent declaring the same trait _alias_ multiples times for various traits. Consequently, the _alias_ will be utilized for the helper methods of the first encountered trait, while helper methods for other traits will be generated as if there were no _alias_. A warning will be displayed in the _Godot Editor_ console.

#### 🔑 Strongly-typed traits and autocompletion

With its code generation tool, _Godot Traits_ makes it easier to write code. The generated helper methods are indeed strongly typed, providing developers with the advantages of both _strong-typed code safety_ and _code completion_, in contrast of duck typing.

_Examples of code completion and code navigation facilitated by the static typing introduced by `GTraits`_

![image](addons/godot-traits/documentation/assets/gtraits_code_completion.png)

![image](addons/godot-traits/documentation/assets/gtraits_code_navigation.gif)


### ➡️ Runtime features

#### 🔑 Strong trait usage runtime checks

#### 🔑 Dynamic addition and removal of traits

#### 🔑 Automatic trait dependency injection

#### 🔑 Traits inheritance

### ➡️ Dynamic trait addition and removal

_Godot Traits_ allows to dynamically add or remove traits to any object at runtime. This allows to conditionally active some behavior without having to maintain a state that must be accessible from anywhere. 

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
    var crate = get_node("crate")
    # Is always safe since we check if the trait is still available on the crate. No 
    # needs maintain an internal crate state saying it's invisible or not
    if GTraits.is_a(Damageable, crate):
        GTraits.as_a(Damageable, crate).take_damage(1)
```

### ➡️ Strong runtime checks

We, as developers, often make strong assumptions on what we have as objects, for example, what kind of node we receive in a callback (_it's always a car !_ for example). But, how to be sure we receive what we intented to receive ? Most of callback methods just return `Node` type objects. Duck typing has some limitations when it comes to debugging your application (_if my object has the __kill__ method then call it, but what happens if it does not have the __kill__ method? No error !_).

_Godot Traits_ offers helpers to retrieve object traits with strong checks: if trait is not available, an assertion error is raised, and Godot Engine debugger stopped at the erroneous frame.

```gdscript
class_name Crate
extends Node2D

func _init() -> void:
    # Create can take damage, but can not be moved !
    GTraits.add_trait_to(Damageable, self)

class_name Game
extends Node2D

func _process_() -> void:
    var crate = get_node("crate")
    # Move the crate only if it is moveable
    # This code does not throw assertion error since we check that the crate is moveable
    if GTraits.is_a(Moveable, crate):
        GTraits.as_a(Moveable, crate).move(Vector2.RIGHT)
    
    # This code will raise an assertion error since we asked for an unknown trait in the crate.If developer assumption is correct, it will always work, else GTraits will help the developer to undertand why its code is not working.
    GTraits.as_a(Moveable, crate).move(Vector2.RIGHT)
```

### ➡️ Automatic trait dependencies injection

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

### ➡️ Trait classes hierarchy

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