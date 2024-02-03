extends RefCounted
class_name GTraitsTraitInitializer

##
## Trait initializer [GTraits].
##
## [color=red]This is an internal API.[/color]

## Initializer parameter
class Parameter extends RefCounted:
    ## Get an instance of the desired parameter
    func get_parameter_instance(receiver:Object, encoutered_traits:Array[Script]) -> Object:
        assert(false, "This method should be overridden")
        return null

class AnyParameter extends Parameter:
    func get_parameter_instance(receiver:Object, encoutered_traits:Array[Script]) -> Object:
        return receiver

class TypedParameter extends Parameter:
    var param_type_name:String
    var param_type:Script

    func _init(ptn:String, pt:Script) -> void:
        param_type_name = ptn
        param_type = pt

    func get_parameter_instance(receiver:Object, encoutered_traits:Array[Script]) -> Object:
        # Two possibilities :
        # - parameter is an instance of the receiver itself : the receiver is the expected parameter
        # - else, parameter is an instance of a trait, so try to get it or instantiate it
        if GTraitsTypeOracle.get_instance().is_object_instance_of(param_type_name, receiver):
            return receiver
        else:
            if not is_instance_valid(param_type):
                assert(false, "⚠️ Trait '%s' can not be found in project." % param_type_name)
                return null

            var trait_instance:Object = GTraitsTraitBuilder.get_instance().instantiate_trait(param_type, receiver, encoutered_traits)
            if not is_instance_valid(trait_instance):
                assert(false, "⚠️ Unable to instantiate trait '%s'." % param_type_name)
                return null

            return trait_instance

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

## The trait owning this initializer
var the_trait:Script
## Name of the initializer method
var name:String
## Returns if this initializer exists or not in a trait.
var exists:bool = true
## Init method argument types. The init callable will require an instance of each to be called
var parameter_types:Array[Parameter]

#------------------------------------------
# Private variables
#------------------------------------------

#------------------------------------------
# Godot override functions
#------------------------------------------

func _init(n:String, a_trait:Script, e:bool = true) -> void:
    name = n
    the_trait = a_trait
    exists = e

#------------------------------------------
# Public functions
#------------------------------------------

## Returns if this initializer takes at least one parameter
func has_parameters() -> bool:
    return not parameter_types.is_empty()

## Returns if this initializer takes no parameter
func has_no_parameters() -> bool:
    return parameter_types.is_empty()

## Invokes this initializer, and returns an initialized trait instance. Trait instance parameter can be
## [code]null[/code], meaning it's
func invoke(receiver:Object, trait_instance:Object, encoutered_traits:Array[Script]) -> Object:
    var parameter_instances:Array[Object] = []
    for param_type in parameter_types:
        var param_instance:Object = param_type.get_parameter_instance(receiver, encoutered_traits)
        if param_instance == null:
             # Something went wrong, can not instantiate objects...
            return null
        parameter_instances.append(param_instance)

    var trait_info:GTraitsTypeOracle.TraitInfo = GTraitsTypeOracle.get_instance().get_trait_info(the_trait)
    if name == "_init":
        if trait_instance != null:
            assert(false, "⚠️ Can not invoke _init function: '%s' trait already instantiated" % trait_info.trait_name)
            return null
        if trait_info.is_scene_trait():
            return ResourceLoader.load(trait_info.trait_scene_path, "PackedScene").instantiate()
        else:
            return the_trait.new.callv(parameter_instances)
    else: # _initialize
        if trait_instance == null:
            assert(false, "⚠️ Can not invoke _initialize function on null instance of '%s' trait" % trait_info.trait_name)
            return null
        if exists:
            trait_instance._initialize.callv(parameter_instances)
        return trait_instance

#------------------------------------------
# Private functions
#------------------------------------------

