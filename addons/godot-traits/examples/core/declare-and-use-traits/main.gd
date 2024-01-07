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
    _npc = preload("res://addons/godot-traits/examples/core/declare-and-use-traits/npc.gd").new()
    add_child(_npc)

func _process(delta: float) -> void:
    _ellapsed_time += delta
    if _ellapsed_time > 2:
        GTraits.as_a(GTraitsCoreExampleKillable, _npc).kill()

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

