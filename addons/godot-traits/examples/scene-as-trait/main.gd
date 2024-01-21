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
    # SelfDestructible is not only a script trait, but it also is a Scene !
    # So GTraits will instantiates the scene itself, and add it to the receiver
    # (the heart) children, allowing complex bahaviors into traits
    GTraits.set_self_destructible(_heart) \
        .after_destruction.connect(func(): _heart.queue_free())

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

