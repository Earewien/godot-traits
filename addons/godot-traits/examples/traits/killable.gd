# @trait
class_name Killable
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

var is_killed: bool = false

#------------------------------------------
# Private variables
#------------------------------------------

var _loggable: Loggable

#------------------------------------------
# Godot override functions
#------------------------------------------

# Loggable trait will automatically be constructed, registered into receiver and injected into
# this constructor, unless receiver already has a Loggable trait, in this case the existing trait
# will be directly injected
func _init(loggable: Loggable) -> void:
    _loggable = loggable

#------------------------------------------
# Public functions
#------------------------------------------

func kill() -> void:
    if not is_killed:
        is_killed = true
        _loggable.log("I've been killed !")

#------------------------------------------
# Private functions
#------------------------------------------
