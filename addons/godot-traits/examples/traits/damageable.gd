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

#------------------------------------------
# Godot override functions
#------------------------------------------

# Automatically requires the trait owner as a dependency, to use it for some logic in this trait
func _init(receiver:Object) -> void:
    _receiver = receiver

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        print("Damageable : I'm beeing freed !")

#------------------------------------------
# Public functions
#------------------------------------------

func take_damage(amount:int) -> void:
    var effective_damage:int = _compute_amount_of_damage(amount)

    # Checks if the object owning this trait is also a Healthable
    # If so, apply damages
    if GTraits.is_a(Healthable, _receiver):
        var healthable:Healthable = GTraits.as_a(Healthable, _receiver)
        if healthable.is_alive():
            print('I took %s damages !' % effective_damage)
            GTraits.as_a(Healthable, _receiver).health -= effective_damage

#------------------------------------------
# Private functions
#------------------------------------------

func _compute_amount_of_damage(initial_amount:int) -> int:
    return initial_amount
