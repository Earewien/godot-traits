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
    # This will raise an assertion error since type NotATrait is not a trait. So it can not be used
    # as a trait. There is no helper methods in the GTraits class for this type, and Godot Traits will
    # not allow its usage as a trait in dependency injection.
    GTraits.add_trait_to(NotATrait, self)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
