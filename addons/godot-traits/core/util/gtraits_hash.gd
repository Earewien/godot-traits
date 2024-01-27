extends RefCounted
class_name GTraitsHash

##
## 'One to many' dictionary for [GTraits].
## [br][br]
## Each key is associated to many values, and each value to one and only one key.
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

# keys to values. One key have multiple values
var _by_keys:Dictionary
# values to key. Each value point to exactly one key
var _by_values:Dictionary

#------------------------------------------
# Godot override functions
#------------------------------------------

func _to_string() -> String:
    return JSON.stringify(_by_keys, "  ")

#------------------------------------------
# Public functions
#------------------------------------------

## Returns if the key exists in this hash
func has_key(key:Variant) -> bool:
    return _by_keys.has(key)

## Returns the key associated to the given value, or [code]null[/code] if the value is not in the hash
func get_key(value:Variant) -> Variant:
    return _by_values.get(value, null)

## Returns values associated to the given key
func get_values(key:Variant, default_value:Array = []) -> Array:
    return _by_keys.get(key, default_value)

## Add a value to the given key. Previous values are kept.
func put_value(key:Variant, value:Variant) -> void:
    var values:Array = get_values(key)
    if not values.has(value):
        values.append(value)
        _by_keys[key] = values

    _by_values[value] = key

## Erase all values associated to the given key
func erase_key(key:Variant) -> Array:
    var values:Array = get_values(key)
    for value in values:
        _by_values.erase(value)
    _by_keys.erase(key)

    return values

## Erase a specific value from the hash.
func erase_value(value:Variant) -> Variant:
    var key:Variant = get_key(value)
    if key != null:
        _by_values.erase(value)
        var values:Array = get_values(key)
        values.erase(value)
        if values.is_empty():
            _by_keys.erase(key)
        else:
            _by_keys[key] = values

    return key

## Returns all values in the hash
func values() -> Array:
    var values:Array = []
    for vals in _by_keys.values():
        values.append_array(vals)
    return values

#------------------------------------------
# Private functions
#------------------------------------------

