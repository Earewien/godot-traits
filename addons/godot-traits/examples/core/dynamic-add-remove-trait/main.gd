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

var _ellapsed_time:float
var _npc

#------------------------------------------
# Godot override functions
#------------------------------------------

func _ready() -> void:
    _npc = preload("res://addons/godot-traits/examples/core/dynamic-add-remove-trait/npc.gd").new()

func _process(delta: float) -> void:
    _ellapsed_time += delta
    
    if _ellapsed_time > 1:
        _ellapsed_time = 0
        if GTraits.is_a(GTraitsCoreExampleDamageable, _npc):
            GTraits.as_a(GTraitsCoreExampleDamageable, _npc).take_damage(1)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _on_incibility_timer_timeout() -> void:
    # NPC has trait GTraitsCoreExampleCriticalDamageable, but we cn remote it using it's super class GTraitsCoreExampleDamageable
    if GTraits.is_a(GTraitsCoreExampleDamageable, _npc):
        print("Removing damageable trait !")
        GTraits.remove_trait_from(GTraitsCoreExampleDamageable, _npc)
    else:
        print("Adding damageable trait !")
        # Is not critical anymore !
        GTraits.add_trait_to(GTraitsCoreExampleDamageable, _npc)

