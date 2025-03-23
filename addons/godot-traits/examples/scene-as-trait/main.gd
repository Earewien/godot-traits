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

@onready var _heart: Polygon2D = $Heart

#------------------------------------------
# Godot override functions
#------------------------------------------

func _ready() -> void:
    GTraits.as_self_destructible(_heart).after_destruction.connect(func():
        GTraits.unset_self_destructible(_heart)
        _heart.queue_free())

    # Scene trait can also be declared directly in code
    GTraits.set_labelled(_heart).text = "Boom !"

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
