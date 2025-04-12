extends RefCounted
class_name GTraitsStorage

##
## Storage utility for [i]Godot Traits[/i].
##
## [color=red]This is an internal API.[/color]


#------------------------------------------
# Constants
#------------------------------------------

## Meta key that stores object traits.
## Meta object is an [Array] of [Script]
const META_TRAIT_SCRIPTS: String = "__traits__"

## Meta key prefix that stores the instantiated trait into an object.
## Meta object is an [Object]
const META_TRAIT_INSTANCE_PREFIX: String = "__trait_"

## Meta key suffix that stores the instantiated trait into an object.
## Meta object is an [Object]
const META_TRAIT_INSTANCE_SUFFIX: String = "__"

## Meta key for trait script
## Meta object is a [Script]
const META_TRAIT_SCRIPT_OBJECT: String = "__trait_script_object__"

## Meta key for scene trait containers type
## Meta object is a [String]: Node, Node2D or Node3D
const META_KEY_CONTAINER_TYPE: String = "__trait_container_type__"

## Meta key for top level trait property
## Meta object is a [bool]
const META_TOP_LEVEL_TRAIT_PROPERTY: String = "__trait_top_level__"

## Meta key to store the parent dependencies of a trait
## Meta object is an [Dictionary] of [WeakRef] as keys and [bool] as values
const META_DEPENDENCIES_PROPERTY: String = "__trait_dependencies__"

## Meta key to store the parent dependencies of a trait
## Meta object is an [Dictionary] of [WeakRef] as keys and [bool] as values
const META_DEPENDENCY_OF_PROPERTY: String = "__trait_dependency_of__"

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

# Singleton
static var _instance: GTraitsStorage

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the instance of [GTraitsStorage]
static func get_instance() -> GTraitsStorage:
    if _instance == null:
        _instance = GTraitsStorage.new()
    return _instance

## Returns an [Array] of [Script] correspondinf to all object traits.
func get_traits(object: Object) -> Array[Script]:
     # First, ensure that the traits storage is available
    if not object.has_meta(META_TRAIT_SCRIPTS):
        # Cast is necessary since an empty Array is not typed by default
        # This avoid class cast at runtime
        object.set_meta(META_TRAIT_SCRIPTS, [] as Array[Script])

    # Then return traits.
    return object.get_meta(META_TRAIT_SCRIPTS) as Array[Script]

## Returns the trait instance for the given object. If trait is not found and [code]fail_if_not_found[/code]
## is [code]true[/code], an assertion error is raised, or else it will returns [code]null[/code].
func get_trait_instance(object: Object, a_trait: Script, fail_if_not_found: bool = false) -> Object:
    var trait_instance_meta_name: String = _get_trait_instance_meta_name(a_trait)
    if object.has_meta(trait_instance_meta_name):
        var traint_instance: Object = object.get_meta(trait_instance_meta_name)
        assert(!fail_if_not_found || is_instance_valid(traint_instance), "Instance of trait '%s' not found or not valid" % GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name)
        return traint_instance
    else:
        if fail_if_not_found:
            assert(false, "⚠️ Instance of trait '%s' not found" % GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name)
        return null

## Stores the trait instance of the object.
## [br][br]
## By default, the trait instance is stored as it's own type. The trait instance can be stored
## as another triat type (to handle trait class hierarchy for example) by specifying the
## [code]as_trait[/code] parameter.
func store_trait_instance(receiver: Object, trait_instance: Object, as_trait: Script = null) -> void:
    if as_trait == null:
        as_trait = trait_instance.get_script()
    receiver.set_meta(_get_trait_instance_meta_name(as_trait), trait_instance)
    # Also store the trait script object into the trait instance, it will be necessary if trait is not top level trait
    # and is auto removed when removing another trait
    if not trait_instance.has_meta(META_TRAIT_SCRIPT_OBJECT):
        trait_instance.set_meta(META_TRAIT_SCRIPT_OBJECT, as_trait)

## Add the trait instance to a trait container, if both trait instance and receiver are [Node] instances.
func add_trait_to_container(receiver: Object, trait_instance: Object) -> void:
    # If both receiver and trait are Node instance, also add trait as a child of the receiver
    if trait_instance is Node and receiver is Node:
        var scene_trait_container: Node = _get_scene_trait_container_for(receiver, trait_instance)
        scene_trait_container.add_child(trait_instance, true, Node.INTERNAL_MODE_BACK)

## Remove a trait from an object.
## [br][br]
## Trait instance is not accessible anymore from it's trait type, or super and sub types.
## It is also automatically freed.
func remove_trait(a_trait: Script, receiver: Object) -> void:
    var trait_instance: Object = get_trait_instance(receiver, a_trait)
    assert(trait_instance != null, "⚠️ Instance of trait '%s' not found" % GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name)

    # First, collect all trait that can be associated to the given trait : super classes and sub classes.
    # All must be removed from the object
    var object_traits: Array[Script] = get_traits(receiver)
    var traits_to_remove: Array[Script] = GTraitsTypeOracle.get_instance().filter_super_script_types_and_sub_script_types_of(object_traits, a_trait)

    # Remove all traits from object, remove trait instance
    for trait_to_remove in traits_to_remove:
        object_traits.erase(trait_to_remove)
        receiver.remove_meta(_get_trait_instance_meta_name(trait_to_remove))

    # If both receiver and trait are Node instance, also remove trait from receiver children
    if trait_instance is Node and receiver is Node:
        var scene_trait_container: Node = _get_scene_trait_container_for(receiver, trait_instance)
        scene_trait_container.remove_child(trait_instance)

    # Free trait instance
    _free_trait_instance(receiver, trait_instance)

## Set the dependency of a trait.
## [br][br]
## This function is used to update the dependency of a trait when it is added to an object.
func set_trait_dependency_of(trait_instance: Object, dependency_of: Object, is_dependency_of_top_level: bool) -> void:
    # Create meta properties if needed, trait instance may already exists
    if not dependency_of.has_meta(META_DEPENDENCIES_PROPERTY):
        dependency_of.set_meta(META_DEPENDENCIES_PROPERTY, {})
    if not dependency_of.has_meta(META_DEPENDENCY_OF_PROPERTY):
        dependency_of.set_meta(META_DEPENDENCY_OF_PROPERTY, {})
    if not dependency_of.has_meta(META_TOP_LEVEL_TRAIT_PROPERTY):
        dependency_of.set_meta(META_TOP_LEVEL_TRAIT_PROPERTY, is_dependency_of_top_level)

    if not trait_instance.has_meta(META_DEPENDENCIES_PROPERTY):
        trait_instance.set_meta(META_DEPENDENCIES_PROPERTY, {})
    if not trait_instance.has_meta(META_DEPENDENCY_OF_PROPERTY):
        trait_instance.set_meta(META_DEPENDENCY_OF_PROPERTY, {})
    if not trait_instance.has_meta(META_TOP_LEVEL_TRAIT_PROPERTY):
        trait_instance.set_meta(META_TOP_LEVEL_TRAIT_PROPERTY, dependency_of == null)

    # Set if this trait is a dependency of another trait or not, and so if it is a top level trait or not
    # This will be necessary to know if we can remove the trait instance when the dependency is removed or not
    if dependency_of != null:
        # The trait is a dependency of another trait, so we need to save it
        dependency_of.get_meta(META_DEPENDENCIES_PROPERTY)[weakref(trait_instance)] = true
        trait_instance.get_meta(META_DEPENDENCY_OF_PROPERTY)[weakref(dependency_of)] = true
        # We DO NOT update the top level trait property here, because it has already been set to true in the previous
        # call to _instantiate_trait, the top level state remains as it was
    else:
        # Not a dependency in this instantiation/retrieval, so it is a top level trait even if there already exists
        # dependencies in other instantiation/retrieval: in this case, it has explicitly been created/retrieved as a top level trait
        trait_instance.set_meta(META_TOP_LEVEL_TRAIT_PROPERTY, true)

#------------------------------------------
# Private functions
#------------------------------------------

func _get_scene_trait_container_for(receiver: Node, trait_instance: Node) -> Node:
    var container: Node = null

    # First, try to find an already existing container
    var required_container_type: String = _get_base_type(trait_instance.get_script().get_instance_base_type())
    for child in receiver.get_children(true):
        if child.get_meta(META_KEY_CONTAINER_TYPE, "") == required_container_type:
            container = child
            break

    # If no container has been found, instanciate one, and add it as a child of the receiver
    if container == null:
        if required_container_type == "Node":
            container = preload("res://addons/godot-traits/core/container/gtraits_container.tscn").instantiate()
            #container.name = "GTraitsContainer"
        elif required_container_type == "Node2D":
            container = preload("res://addons/godot-traits/core/container/gtraits_container_2d.tscn").instantiate()
            #container.name = "GTraitsContainer2D"
        elif required_container_type == "Node3D":
            container = preload("res://addons/godot-traits/core/container/gtraits_container_3d.tscn").instantiate()
            #container.name = "GTraitsContainer3D"
        elif required_container_type == "Control":
            container = preload("res://addons/godot-traits/core/container/gtraits_container_control.tscn").instantiate()
            #container.name = "GTraitsContainerControl"
        else:
            assert(false, "⚠️ Unknow type of container: %s" % required_container_type)
        receiver.add_child(container, true, Node.INTERNAL_MODE_BACK)

    return container

func _get_base_type(type_name: String) -> String:
    # Check if the class is registered in ClassDB
    if not ClassDB.class_exists(type_name):
        assert(false, "⚠️ Unknow type: %s" % type_name)
        return ''

    if type_name == 'Node' \
        || type_name == 'Node2D' \
        || type_name == 'Node3D' \
        || type_name == 'Control':
        return type_name

    # Check the parent
    return _get_base_type(ClassDB.get_parent_class(type_name))

func _get_trait_instance_meta_name(a_trait: Script) -> String:
    return META_TRAIT_INSTANCE_PREFIX + GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name + META_TRAIT_INSTANCE_SUFFIX

func _free_trait_instance(receiver: Object, trait_instance: Object) -> void:
    # Free dependencies if needed
    _remove_trait_dependencies(receiver, trait_instance)

    # Free trait instance
    if GTraitsTypeOracle.get_instance().is_object_instance_of("Node", trait_instance):
        trait_instance.queue_free()
    elif GTraitsTypeOracle.get_instance().is_object_instance_of("RefCounted", trait_instance):
        # Do nothing, will be garbage collected by Godot Engine
        pass
    else:
        trait_instance.free()

func _remove_trait_dependencies(receiver: Object, trait_instance: Object) -> void:
    # Remove this trait from the dependency of other traits
    var dependency_of: Dictionary = trait_instance.get_meta(META_DEPENDENCY_OF_PROPERTY)
    for dependency_of_trait in dependency_of:
        if dependency_of_trait.get_ref() != null:
            dependency_of_trait.get_ref().get_meta(META_DEPENDENCIES_PROPERTY).erase(weakref(trait_instance))

    # Check if this trait has been marked to destroy its dependencies or not
    var trait_instance_script: Script = trait_instance.get_meta(META_TRAIT_SCRIPT_OBJECT)
    if not trait_instance_script.get_meta("__trait_on_destroy_destroy_dependencies", true):
        return

    # Remove this trait dependencies from the receiver
    var dependencies: Dictionary = trait_instance.get_meta(META_DEPENDENCIES_PROPERTY)
    for dependency in dependencies:
        if dependency.get_ref() != null:
            # Only auto remove non top level dependencies
            var is_top_level: bool = dependency.get_ref().get_meta(META_TOP_LEVEL_TRAIT_PROPERTY)
            if not is_top_level:
                # Only remove the trait if it is not used by another trait
                var dependency_used_by: Dictionary = dependency.get_ref().get_meta(META_DEPENDENCY_OF_PROPERTY)
                var dependency_used_by_objects: Array = dependency_used_by.keys().duplicate()
                for dependency_used_by_object in dependency_used_by_objects:
                    if dependency_used_by_object.get_ref() == trait_instance:
                        dependency_used_by.erase(dependency_used_by_object)
                if dependency_used_by.is_empty():
                    var dependency_script: Script = dependency.get_ref().get_meta(META_TRAIT_SCRIPT_OBJECT)
                    remove_trait(dependency_script, receiver)
                    print("destroying a dependency")
