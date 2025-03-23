# @trait
class_name SelfDestructible
extends Node2D

# This script is the scene "SelfDestructible" root script. Since it's a trait, it makes
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

signal after_destruction

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Public variables
#------------------------------------------

#------------------------------------------
# Private variables
#------------------------------------------

@onready var _explosion_particules: CPUParticles2D = $ExplosionParticules
@onready var _self_desctruct_timer: Timer = $SelfDestructTimer

# The trait receiver
var _receiver
# The logger
var _logger: Loggable

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
func _initialize(receiver, logger: Loggable) -> void:
    _receiver = receiver
    _logger = logger

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _on_self_desctruct_timer_timeout() -> void:
    _explosion_particules.emitting = true
    get_tree().create_tween().tween_property(_receiver, "modulate:a", 0, _self_desctruct_timer.wait_time / 2)

func _on_explosion_particules_finished() -> void:
    after_destruction.emit()
