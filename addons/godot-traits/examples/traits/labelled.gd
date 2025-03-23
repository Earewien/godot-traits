# @trait
class_name Labelled
extends Label

# This script is the scene "Labelled" root script. Since it's a trait, it makes
# the whole scene treated as a trait. Godot Traits will instantitates the scene itself when
# it will be required instead of the script.
#
# Since Node traits are added as children of their receiver, it is possible to write some Node
# specific bahavior into those kind of traits!

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

# The trait receiver
var _receiver: Node2D

#------------------------------------------
# Godot override functions
#------------------------------------------

# Since this trait is also a Scene, the _init function must take exactly 0 parameter, otherwise the scene
# can not be instantiated. It's still possible do do stuff in the _init function, but there will be no Godot Traits
# injection in it. Instead, declare an _initialize function
func _init() -> void:
    pass

# Since this trait is also a Scene, the _init function can not be overridden with parameters. To overcome this issue,
# Godot Traits will automatically call the _initialize function, if it exists, right after the Scene instantiation.
func _initialize(receiver: Node2D) -> void:
    _receiver = receiver

func _process(_delta: float) -> void:
    _update_position()

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _update_position() -> void:
    global_position = _receiver.global_position - Vector2(0, 75)
