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
    print("Is a Killable : %s" % GTraitsCore.is_a(GTraitsCoreExampleKillable, npc))
    # Will print false !
    print("Is a Healthable : %s" % GTraitsCore.is_a(GTraitsCoreExampleHealthable, npc))
    # Will raise an assertion error, since getting a non existing trait is forbidden !
    # with message 'Instance of trait 'GTraitsCoreExampleHealthable' not found'
    GTraitsCore.as_a(GTraitsCoreExampleHealthable, npc)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
