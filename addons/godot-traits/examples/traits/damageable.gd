# @trait
class_name Damageable


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

# The object that has this trait
var _receiver:Object
# The Loggable trait of the receiver, can be injected into _init method
# or it can be retrieved using GTraits.as_loggable(_receiver)
var _loggable:Loggable

#------------------------------------------
# Godot override functions
#------------------------------------------

# Automatically requires the trait receiver as a dependency, to use it for some logic in this trait
# Also required the receiver Loggable trait. If it's not Loggable, it will automatically become Loggable
func _init(receiver:Object, loggable:Loggable) -> void:
    _receiver = receiver
    _loggable = loggable

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        _loggable.log("I'm beeing freed !")

#------------------------------------------
# Public functions
#------------------------------------------

func take_damage(amount:int) -> void:
    var effective_damage:int = _compute_amount_of_damage(amount)

    # Checks if the object owning this trait is also a Healthable
    # If so, apply damages
    GTraits.if_is_healthable(_receiver, _apply_damages.bind(effective_damage))

#------------------------------------------
# Private functions
#------------------------------------------

func _compute_amount_of_damage(initial_amount:int) -> int:
    return initial_amount

func _apply_damages(healthable:Healthable, effective_damage:int) -> void:
    if healthable.is_alive():
        healthable.health -= effective_damage
