# @trait
class_name Loggable
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

#------------------------------------------
# Private variables
#------------------------------------------

var _log_context:String

#------------------------------------------
# Godot override functions
#------------------------------------------

# Automatically requires the trait receiver as a dependency
func _init(receiver) -> void:
    _log_context = str(receiver.get_instance_id())

#------------------------------------------
# Public functions
#------------------------------------------

func log(message:String) -> void:
    print("%s| %s" % [_log_context, message])

#------------------------------------------
# Private functions
#------------------------------------------

