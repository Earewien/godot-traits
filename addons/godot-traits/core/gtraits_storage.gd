extends RefCounted
class_name GTraitsStorage

##
## Storage utility for [GTraits].
##
## [color=red]This is an internal API.[/color]


#------------------------------------------
# Constants
#------------------------------------------

## Meta key that stores object traits.
## Meta object is an [Array] of [Script]
const META_TRAIT_SCRIPTS:String = "__traits__"

## Meta key that stores the trait class name (the defined class_name) in a trait script
## Meta object is a [String]
const META_TRAIT_CLASS_NAME:String = "__trait_name_"

## Meta key prefix that stores the instantiated trait into an object.
## Meta object is an [Object]
const META_TRAIT_INSTANCE_PREFIX:String = "__trait_"

## Meta key suffix that stores the instantiated trait into an object.
## Meta object is an [Object]
const META_TRAIT_INSTANCE_SUFFIX:String = "__"

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

var _type_oracle:GTraitsTypeOracle = GTraitsTypeOracle.new()

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the trait class name, as defined in the trait script through the [code]class_name[/code]
## keyword. Raise an assertion error if class name can not be determined.
func get_trait_class_name(a_trait:Script) -> String:
    return _get_trait_class_name(a_trait)

## Returns an [Array] of [Script] correspondinf to all object traits.
func get_traits(object:Object) -> Array[Script]:
     # First, ensure that the traits storage is available
    if not object.has_meta(META_TRAIT_SCRIPTS):
        # Cast is necessary since an empty Array is not typed by default
        # This avoid class cast at runtime
        object.set_meta(META_TRAIT_SCRIPTS, [] as Array[Script])

    # Then return traits.
    return object.get_meta(META_TRAIT_SCRIPTS) as Array[Script]

## Returns the trait instance for the given object. If trait is not found and [code]fail_if_not_found[/code]
## is [code]true[/code], an assertion error is raised, or else it will returns [code]null[/code].
func get_trait_instance(object:Object, a_trait:Script, fail_if_not_found:bool = false) -> Object:
    var trait_instance_meta_name:String = _get_trait_instance_meta_name(a_trait)
    if object.has_meta(trait_instance_meta_name):
        var traint_instance:Object = object.get_meta(trait_instance_meta_name)
        assert(!fail_if_not_found || is_instance_valid(traint_instance), "Instance of trait '%s' not found or not valid" % _get_trait_class_name(a_trait))
        return traint_instance
    else:
        if fail_if_not_found:
            assert(false, "Instance of trait '%s' not found" % _get_trait_class_name(a_trait))
        return null

## Stores the trait instance of the object.
## [br][br]
## By default, the trait instance is stored as it's own type. The trait instance can be stored
## as another triat type (to handle trait class hierarchy for example) by specifying the
## [code]as_trait[/code] parameter.
func store_trait_instance(object:Object, trait_instance:Object, as_trait:Script = null) -> void:
    if as_trait == null:
        as_trait = trait_instance.get_script()
    object.set_meta(_get_trait_instance_meta_name(as_trait), trait_instance)

    # If both receiver and trait are Node instance, also add trait as a child of the receiver
    if trait_instance is Node and object is Node:
        (object as Node).add_child(trait_instance, true, Node.INTERNAL_MODE_DISABLED)

## Remove a trait from an object.
## [br][br]
## Trait instance is not accessible anymore from it's trait type, or super and sub types.
## It is also automatically freed.
func remove_trait(a_trait:Script, object:Object) -> void:
    var trait_instance:Object = get_trait_instance(object, a_trait)
    assert(trait_instance != null, "Instance of trait '%s' not found" % _get_trait_class_name(a_trait))

    # First, collect all trait that can be associated to the given trait : super classes and sub classes.
    # All must be removed from the object
    var object_traits:Array[Script] = get_traits(object)
    var traits_to_remove:Array[Script] = _type_oracle.filter_super_script_types_and_sub_script_types_of(object_traits, a_trait)

    # Remove all traits from object, remove trait instance
    for trait_to_remove in traits_to_remove:
        object_traits.erase(trait_to_remove)
        object.remove_meta(_get_trait_instance_meta_name(trait_to_remove))

    # If both receiver and trait are Node instance, also remove trait from receiver children
    if trait_instance is Node and object is Node:
        (object as Node).remove_child(trait_instance)

    # Free trait instance
    _free_trait_instance(trait_instance)

#------------------------------------------
# Private functions
#------------------------------------------

func _get_trait_instance_meta_name(a_trait:Script) -> String:
    return META_TRAIT_INSTANCE_PREFIX + _get_trait_class_name(a_trait) + META_TRAIT_INSTANCE_SUFFIX

func _get_trait_class_name(a_trait:Script) -> String:
    if not a_trait.has_meta(META_TRAIT_CLASS_NAME):
        var trait_class_name:String = _type_oracle.get_script_class_name(a_trait)
        if trait_class_name.is_empty():
            trait_class_name = "script_%s" % str(a_trait.get_instance_id()).replace('-', '_')
        #assert(not trait_class_name.is_empty(), "Can not determine class name for trait '%s'" % a_trait.resource_path)
        a_trait.set_meta(META_TRAIT_CLASS_NAME, trait_class_name)

    return a_trait.get_meta(META_TRAIT_CLASS_NAME)

func _free_trait_instance(trait_instance:Object) -> void:
    if _type_oracle.is_object_instance_of("Node", trait_instance):
        trait_instance.queue_free()
    elif _type_oracle.is_object_instance_of("RefCounted", trait_instance):
        # Do nothing, will be garbage collected by Godot Engine
        pass
    else:
        trait_instance.free()

