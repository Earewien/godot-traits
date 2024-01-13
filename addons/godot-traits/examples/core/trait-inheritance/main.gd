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

var _npc:Node2D

#------------------------------------------
# Private variables
#------------------------------------------

func _ready() -> void:
    _npc = preload("res://addons/godot-traits/examples/core/trait-inheritance/npc.gd").new()
    # Takes 20 damages, as it called the critical damage trait !
    GTraits.as_critical_damageable(_npc).take_damage(10)
    # Also take 20 damages, as it also called the critical damage trait
    GTraits.as_damageable(_npc).take_damage(10)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

