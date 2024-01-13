# @trait
class_name CriticalDamageable
extends Damageable


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

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        print("GTraitsCoreExampleCriticalDamageable : I'm beeing freed !")

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _compute_amount_of_damage(initial_amount:int) -> int:
    return initial_amount * 2
