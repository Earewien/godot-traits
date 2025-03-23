class_name InnerTraits

# Demonstrate inner class trait declaration

# @trait(alias=Moveable)
class Moveable extends RefCounted:
    # This is the receiver as a CharacterBody2D
    var _character: CharacterBody2D

    func _init(character: CharacterBody2D) -> void:
        _character = character

    func move(dir: Vector2) -> void:
        _character.velocity += dir * 300
        _character.move_and_slide()

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

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------
