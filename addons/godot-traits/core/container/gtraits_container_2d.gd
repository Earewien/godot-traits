@icon("res://addons/godot-traits/core/container/gtraits_container_icon_2d.svg")
class_name GTraitsContainer2D
extends GTraitsContainer

##
## Trait container for 2D scene traits, allowing to declare scene traits directly in [i]Godot Editor[/i].
##
## See [GTraitsContainer] for documentation.
##

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

#------------------------------------------
# Private functions
#------------------------------------------

func _set_trait_container_type() -> void:
    # Flagging this container as Node2D scene trait container. For trait storage at runtime
    set_meta(GTraitsStorage.META_KEY_CONTAINER_TYPE, "Node2D")
