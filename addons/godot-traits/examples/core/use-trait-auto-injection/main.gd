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

var _ellapsed_time:float = 0
var _npc:Node2D

#------------------------------------------
# Godot override functions
#------------------------------------------

func _ready() -> void:
    _npc = preload("res://addons/godot-traits/examples/core/use-trait-auto-injection/npc.gd").new()
    add_child(_npc)

func _process(delta: float) -> void:
    _ellapsed_time += delta
    if _ellapsed_time > 0.5:
        _ellapsed_time = 0
        GTraitsCore.as_a(GTraitsCoreExampleDamageable, _npc).take_damage(10)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

