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

func _ready() -> void:
    var npc = preload("res://addons/godot-traits/examples/core/trait-runtime-checks/npc.gd").new()
    # Will print true !
    print("Is a Killable : %s" % GTraits.is_a_killable(npc))
    # Will print false !
    print("Is a Healthable : %s" % GTraits.is_a_healthable(npc))
    # Will raise an assertion error, since getting a non existing trait is forbidden !
    # with message 'Instance of trait 'Healthable' not found'
    GTraits.as_healthable(npc)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
