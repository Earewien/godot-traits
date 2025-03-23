extends Node2D

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

func _ready() -> void:
    # By setting this object as a Cyclic1, Gtraits will auto instantiate all its dependencies:
    # so Cyclic2, Cyclic3, then Cyclic4. But Cyclic4 requires a Cyclic2 to be instantiate. It's a cyclic
    # dependencies and it will raise an assertion error
    GTraits.set_cyclic_1(self)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
