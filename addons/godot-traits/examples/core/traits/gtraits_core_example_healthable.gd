extends RefCounted
class_name GTraitsCoreExampleHealthable

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

var max_health:int = 100
var health:int = max_health:
    set(value):
        health = clamp(value, 0, max_health)
        if value <= 0:
            _killable.kill()

#------------------------------------------
# Private variables
#------------------------------------------

# Reference to the GTraitsCoreExampleKillable, needed for this trait to handle death !
var _killable:GTraitsCoreExampleKillable

#------------------------------------------
# Godot override functions
#------------------------------------------

# Automatically requires that the trait owner is also a GTraitsCoreExampleKillable object
# GTraitsCoreExampleKillable trait must be declared before this trait since it's a dependency
func _init(killable:GTraitsCoreExampleKillable) -> void:
    _killable = killable

#------------------------------------------
# Public functions
#------------------------------------------

func is_alive() -> bool:
    return not _killable.is_killed

#------------------------------------------
# Private functions
#------------------------------------------

