extends Node
# @trait
class_name Cyclic4

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

# Explicitly requires Cyclic2 trait, but Cyclic2 requires Cyclic3 trait
# that requires Cycle4 trait
# It's a cyclic dependency, Godot Traits will throw an assertion error
func _init(cyclic2: Cyclic2) -> void:
    pass

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

