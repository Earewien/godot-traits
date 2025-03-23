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

#------------------------------------------
# Godot override functions
#------------------------------------------

func _init() -> void:
    # Healthable trait depends on Killable trait, so by setting this NPC Healthable, it will
    # also be Killable ! Healthable and Killable requires a Loggable to work, so the NPC will
    # became a Loggable too
    GTraits.set_healthable(self)
    assert(GTraits.is_killable(self), "Should be killable !")
    assert(GTraits.is_loggable(self), "Should be loggable !")
    GTraits.set_critical_damageable(self)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
