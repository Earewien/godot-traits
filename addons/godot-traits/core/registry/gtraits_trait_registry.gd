extends RefCounted
class_name GTraitsTraitRegistry

##
## Registry for [GTraits].
##
## [color=red]This is an internal API.[/color]

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
static var _instance:GTraitsTraitRegistry

# All known traits, for dep injection. As a dictionary to check trait in o(1)
# Key is the trait script, value is the path to the trait scene if there is one
var _known_traits:Dictionary

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsTraitRegistry] singleton
static func get_instance() -> GTraitsTraitRegistry:
    if _instance == null:
        _instance = GTraitsTraitRegistry.new()
    return _instance

## Declare a class as a trait, making it available for dependency injection. If the scene path is not empty,
## the given scene will be instantiated instead of the given script when a trait instance will be needed
func register_trait(a_trait:Script, scene_path:String = "") -> void:
    _known_traits[a_trait] = scene_path

## Returns [code]true[/code] is the given object is a trait, [code]false[/code] otherwise.
func is_trait_object(object:Object) -> bool:
    if not is_instance_valid(object):
        return false

    var script:Script = object.get_script()
    return is_trait(object.get_script())

## Returns [code]true[/code] is the given class is a trait, [code]false[/code] otherwise.
func is_trait(script:Script) -> bool:
    return _known_traits.has(script)

## Returns [code]true[/code] is the given object is a scene trait, [code]false[/code] otherwise.
func is_scene_trait_object(object:Object) -> bool:
    if not is_instance_valid(object):
        return false

    return is_scene_trait(object.get_script())

## Returns [code]true[/code] is the given class is a scene trait, [code]false[/code] otherwise.
func is_scene_trait(script:Script) -> bool:
    return not _known_traits.get(script, "").is_empty()

## Returns the scene path for the given scene trait, or an empty [String] if the given type is not a trait
## or a scene trait.
func get_scene_trait_scene_path(script:Script) -> String:
    return _known_traits.get(script, "")

#------------------------------------------
# Private functions
#------------------------------------------

