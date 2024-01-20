# @trait
class_name Healthable
extends RefCounted


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
        var old_health:int = health
        health = clamp(value, 0, max_health)
        if old_health != health:
            _loggable.log("HP : %s/%s" % [health, max_health])
            if value <= 0:
                _killable.kill()

#------------------------------------------
# Private variables
#------------------------------------------

# Reference to the Loggable, needed for this trait to print messages
var _loggable:Loggable
# Reference to the Killable, needed for this trait to handle death !
var _killable:Killable

#------------------------------------------
# Godot override functions
#------------------------------------------

# Automatically requires that the trait receiver is also a Killable and a Loggable object
# If the receiver does not have those traits yet, they will be automatically instantiated and
# registered into the receiver for future usages.
func _init(killable:Killable, loggable:Loggable) -> void:
    _killable = killable
    _loggable = loggable

#------------------------------------------
# Public functions
#------------------------------------------

func is_alive() -> bool:
    return not _killable.is_killed

#------------------------------------------
# Private functions
#------------------------------------------

