extends RefCounted
class_name GTraitsTypeOracle

##
## Type Oracle for [i]Godot Traits[/i].
##
## [color=red]This is an internal API.[/color]

## Trait information
class TraitInfo extends RefCounted:
    ## Trait qualified name
    var trait_name: String
    ## Trait unique identifier
    var trait_identifier: String
    ## Script defining the trait
    var trait_type: Script
    ## If trait is a scene, trait scene path, empty otherwise
    var trait_scene_path: String

    func _init(tn: String, tt: Script, tsp: String) -> void:
        trait_name = tn
        trait_identifier = "_%s_" % trait_name.replace(".", "_").to_lower()
        trait_type = tt
        trait_scene_path = tsp

    ## Returns if this trait is a scene trait or not.
    func is_scene_trait() -> bool:
        return not trait_scene_path.is_empty()

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

# Singleton
static var _instance: GTraitsTypeOracle

# All known traits. As a dictionary to check trait in O(1)
# Key is the trait script, value is a TraitInfo
var _known_traits: Dictionary

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsTypeOracle] singleton
static func get_instance() -> GTraitsTypeOracle:
    if _instance == null:
        _instance = GTraitsTypeOracle.new()
    return _instance

## Returns the class name of a [Script], as defined by the [code]class_name[/code] keyword.
## If class name if not found, returns an empty [String].
func get_script_class_name(script: Script) -> String:
    for global_class in ProjectSettings.get_global_class_list():
        if global_class["path"] == script.resource_path:
            return global_class['class']
    return ''

## Returns the [Script] instance corresponding to the given class name. If no script is found,
## returns [code]null[/code]
func get_script_from_class_name(a_class_name: String) -> Script:
    for global_class in ProjectSettings.get_global_class_list():
        if global_class["class"] == a_class_name:
            return load(global_class["path"])
    return null

## Checks that an object is of a certain class.
func is_object_instance_of(a_class_name: String, object: Object) -> bool:
    if ClassDB.class_exists(a_class_name):
        # It's a built-in object (like Node2D, CharacterBody2D, ...)
        return object.is_class(a_class_name)
    else:
        # It surely is a user-defined type, try to load it
        var class_script: Script = get_script_from_class_name(a_class_name)

        if class_script == null:
            # User-defined script but can't find it.
            return false

        # Now, it's time to compare this object script instance and the expected
        # class script instance. Don't forget to check for object script super-classes
        # (base scripts) since we can check for inheritance classes
        var object_script: Script = object.get_script()
        while object_script != null:
            if object_script == class_script:
                return true
            # Check parent now
            object_script = object_script.get_base_script()

        return false

## Returns an [Array] of [Script] containing only super clsses and sub-classes of the given type.
## Type itself [b]is[/b] included in the result.
func filter_super_script_types_and_sub_script_types_of(scripts: Array[Script], script: Script) -> Array[Script]:
    var filtered_scripts: Array[Script] = [] as Array[Script]
    var script_super_types: Array[Script] = _get_super_script_types_of(script)

    for a_script in scripts:
        if script_super_types.has(a_script) or _get_super_script_types_of(a_script).has(script):
            filtered_scripts.append(a_script)

    filtered_scripts.append(script)

    return filtered_scripts

## Declare a class as a trait, making it available for dependency injection. If the scene path is not empty,
## the given scene will be instantiated instead of the given script when a trait instance will be needed
func register_trait(a_trait: Script, a_trait_name: String, on_destroy_destroy_dependencies: bool = true, scene_path: String = "") -> void:
    _known_traits[a_trait] = TraitInfo.new(a_trait_name, a_trait, scene_path)
    a_trait.set_meta("__trait_on_destroy_destroy_dependencies", on_destroy_destroy_dependencies)

## Returns [code]true[/code] is the given class is a trait, [code]false[/code] otherwise.
func is_trait(script: Script) -> bool:
    return _known_traits.has(script)

## Returns an instance of [GTraitsTypeOracle.TraitInfo] describing the given type, [code]null[/code] otherwise.
func get_trait_info(script: Script) -> TraitInfo:
    return _known_traits.get(script, null)

#------------------------------------------
# Private functions
#------------------------------------------

func _get_super_script_types_of(script: Script) -> Array[Script]:
    var super_script_types: Array[Script] = [] as Array[Script]
    var super_script: Script = script.get_base_script()
    while (super_script != null):
        super_script_types.append(super_script)
        super_script = super_script.get_base_script()
    return super_script_types
