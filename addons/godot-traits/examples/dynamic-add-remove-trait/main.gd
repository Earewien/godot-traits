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

var _ellapsed_time: float
var _npc

#------------------------------------------
# Godot override functions
#------------------------------------------

func _ready() -> void:
    _npc = preload("res://addons/godot-traits/examples/dynamic-add-remove-trait/npc.gd").new()

func _process(delta: float) -> void:
    _ellapsed_time += delta

    if _ellapsed_time > 1:
        _ellapsed_time = 0
        GTraits.if_is_damageable(_npc, func(damageable: Damageable): damageable.take_damage(5))
        # Can also be write as:
        #if GTraits.is_damageable(_npc):
            #GTraits.as_damageable(_npc).take_damage(1)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _on_incibility_timer_timeout() -> void:
    # NPC has trait CriticalDamageable, but we cn remote it using it's super class Damageable
    # Can also be write as:
    GTraits.if_is_damageable_or_else(_npc, func(any): GTraits.unset_damageable(_npc), func(): GTraits.set_damageable(_npc))
    ## Can also be write as:
    #if GTraits.is_damageable(_npc):
        #GTraits.unset_damageable(_npc)
    #else:
        ## Is not critical anymore !
        #GTraits.set_damageable(_npc)
