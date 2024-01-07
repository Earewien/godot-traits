extends RefCounted
class_name GTraitsTypeOracle

## 
## Type Oracle [GTraits].
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

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the class name of a [Script], as defined by the [code]class_name[/code] keyword.
## If class name if not found, returns an empty [String].
func get_script_class_name(script:Script) -> String:
    for global_class in ProjectSettings.get_global_class_list():
        if global_class["path"] == script.resource_path:
            return global_class['class']
    return ''

## Returns the [Script] instance corresponding to the given class name. If no script is found,
## returns [code]null[/code]
func get_script_from_class_name(a_class_name:String) -> Script:
    for global_class in ProjectSettings.get_global_class_list():
        if global_class["class"] == a_class_name:
            return load(global_class["path"])
    return null

## Checks that an object is of a certain class.
func is_object_instance_of(a_class_name:String, object:Object) -> bool:
    if ClassDB.class_exists(a_class_name):
        # It's a built-in object (like Node2D, CharacterBody2D, ...)
        return object.is_class(a_class_name)
    else:
        # It surely is a user-defined type, try to load it
        var class_script:Script = get_script_from_class_name(a_class_name)

        if class_script == null:
            # User-defined script but can't find it.
            return false

        # Now, it's time to compare this object script instance and the expected
        # class script instance. Don't forget to check for object script super-classes
        # (base scripts) since we can check for inheritance classes
        var object_script:Script = object.get_script()
        while object_script != null:
            if object_script == class_script:
                return true
            # Check parent now
            object_script = object_script.get_base_script()

        return false

## Returns an [Array] of [Script] containing only super clsses and sub-classes of the given type. 
## Type itself [b]is[/b] included in the result.
func filter_super_script_types_and_sub_script_types_of(scripts:Array[Script], script:Script) -> Array[Script]:
    var filtered_scripts:Array[Script] = [] as Array[Script]
    var script_super_types:Array[Script] = _get_super_script_types_of(script)
    
    for a_script in scripts:
        if script_super_types.has(a_script) or _get_super_script_types_of(a_script).has(script):
            filtered_scripts.append(a_script)
    
    filtered_scripts.append(script)
    
    return filtered_scripts
        
#------------------------------------------
# Private functions
#------------------------------------------

func _get_super_script_types_of(script:Script) -> Array[Script]:
    var super_script_types:Array[Script] = [] as Array[Script]
    var super_script:Script = script.get_base_script()
    while(super_script != null):
        super_script_types.append(super_script)
        super_script = super_script.get_base_script()
    return super_script_types