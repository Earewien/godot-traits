class_name GTraitsCore

##
## Traits made easy in Godot.
##
## Traits are set of variables, functions and behaviors that can be use to extend
## the functionnalities of a class. This concept does not exist (yet!) in Godot,
## but it can be emulated in order to ease game developement.
##
## [br][br]
## This class offers way to handle traits in any Godot object, by dynamically adding
## or removing behaviors to them at runtime.
##
## [br][br]
## [b]Examples[/b]
## [br][br]
## Add trait to an object
## [codeblock]
## # In object class
## func _init() -> void:
##     # Add Damageable trait to this object
##     GTraitsCore.add_trait_to(Damageable, self)
##
## # Elsewhere
## func _on_body_entered(body:Node2D) -> void:
##     # Automatically checks that body has a Damageable trait, break code if
##     # body has no Damageable trait, useful to debug and assert things.
##     GTraitsCore.as_a(Damageable, body).take_damage(10)
##
## [/codeblock]
##
## [br][br]
## Strong typing and code completion can not be achieved through this unique class,
## since [method GTraitsCore.as_a] returned type is [Object]. To achieve strong type and
## code completion, use the automatic trait invoker generated code.
##
## [br][br]
## [color=red]Changes can occurs in API since it's in development phase.[/color]
## @experimental

#------------------------------------------
# Constants
#------------------------------------------

#------------------------------------------
# Signals
#------------------------------------------

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Public variables
#------------------------------------------

#------------------------------------------
# Private variables
#------------------------------------------

static var _traits_storage:GTraitsStorage = GTraitsStorage.new()

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Declare a class as a trait. It then becomes available for several operations on trait.
## [br][br]
## If the [code]scene_path[/code] is not empty, the trait is registered as a [i]Scene trait[/i]. When
## used, the scene will be instantiated instead of the trait script.
static func register_trait(a_trait:Script, a_trait_name:String, scene_path:String = "") -> void:
    GTraitsTypeOracle.get_instance().register_trait(a_trait, a_trait_name, scene_path)

## Returns [code]true[/code] if an object has a given trait, [code]false[/code] otherwise.
static func is_a(a_trait:Script, object:Object) -> bool:
    if not is_instance_valid(object):
        return false
    return is_instance_valid(_traits_storage.get_trait_instance(object, a_trait))

## Add a trait to the given object and returns the instantiated trait. If trait already exists in
## the object, it is immediatly returned.
static func add_trait_to(a_trait:Script, object:Object) -> Object:
    assert(is_instance_valid(a_trait), "Trait must be a valid script (noll null or freed)")
    assert(is_instance_valid(object), "Object must be a valid object (noll null or freed)")

    # 2 possibilities:
    # - trait already exists in this object (multiple call to add_trait_to): retrieve
    # already instantiated trait
    # - trait does not exist: instantiate it, add it to the object
    var trait_instance:Object
    var object_traits:Array[Script] = _traits_storage.get_traits(object)
    if object_traits.has(a_trait):
        # If object already has the trait, instance must be present ! If not, there is an issue
        trait_instance = _traits_storage.get_trait_instance(object, a_trait, true)
    else:
        # Register trait into object, and instantiate it
        object_traits.push_back(a_trait)
        trait_instance = GTraitsTraitBuilder.get_instance().instantiate_trait(a_trait, object, [])

    return trait_instance

## Remove a trait from the given object and returns it. Removed trait is automatically freed from memory.
## If trait is not available in the given object, an assertion error will be raised.
static func remove_trait_from(a_trait:Script, object:Object) -> void:
    _traits_storage.remove_trait(a_trait, object)

## Returns the trait instance for the given object. If this object does not have this trait,
## an assertion error will be raised.
static func as_a(a_trait:Script, object:Object) -> Object:
    return _traits_storage.get_trait_instance(object, a_trait, true)

## Calls the given [Callable] if and only if an object has a given trait. The callable
## takes the asked trait as argument. Returns the callable result if the object has the
## given trait, [code]null[/code] otherwise.
## [br][br]
## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and
## the returned value will always be [code]null[/code].
## [br][br]
## See [method GTraitsCore.is_a] for more details about trait testing.
static func if_is_a(a_trait:Script, object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:
    var trait_instance:Object = _traits_storage.get_trait_instance(object, a_trait)
    if trait_instance != null:
        assert(if_callable.is_valid(), "Callable must be valid")
        if deferred_call:
            if_callable.call_deferred(trait_instance)
            return null
        else:
            return if_callable.call(trait_instance)
    return null

## Calls the given [i]if[/i] [Callable] if and only if an object has a given trait, or else calls
## the given [i]else[/i] callable. The [i]if[/i] callable takes the asked trait as argument, and the
## [i]else[/i] callable does not take any argument. Returns the called callable result.
## [br][br]
## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and
## the returned value will always be [code]null[/code].
## [br][br]
## See [method GTraitsCore.is_a] for more details about trait testing.
static func if_is_a_or_else(a_trait:Script, object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:
    var trait_instance:Object = _traits_storage.get_trait_instance(object, a_trait)
    if trait_instance != null:
        assert(if_callable.is_valid(), "Callable must be valid")
        if deferred_call:
            if_callable.call_deferred(trait_instance)
            return null
        else:
            return if_callable.call(trait_instance)
    else:
        assert(else_callable.is_valid(), "Callable must be valid")
        if deferred_call:
            else_callable.call_deferred()
            return null
        else:
            return else_callable.call()

#------------------------------------------
# Private functions
#------------------------------------------

