extends RefCounted
class_name GTraitsTraitBuilder

##
## Trait builder for [GTraits].
##
## [color=red]This is an internal API.[/color]
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

var _traits_storage:GTraitsStorage = GTraitsStorage.new()
var _type_oracle:GTraitsTypeOracle = GTraitsTypeOracle.new()

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

func instantiate_trait(a_trait:Script, receiver:Object) -> Object:
    return _instantiate_trait(a_trait, receiver)

#------------------------------------------
# Private functions
#------------------------------------------

func _instantiate_trait(a_trait:Script, receiver:Object, encoutered_traits:Array[Script] = []) -> Object:
    # Check there is no cyclic dependencies in progress
    if encoutered_traits.has(a_trait):
        var cyclic_dependency_string:String = encoutered_traits \
            .map(_type_oracle.get_script_class_name) \
            .reduce(func(accum, name): return "%s -> %s" % [accum, name])
        cyclic_dependency_string = "%s -> %s" % [cyclic_dependency_string, _type_oracle.get_script_class_name(a_trait)]
        assert(false, "⚠️ Cyclic depdendency detected during trait instantiation: %s" % cyclic_dependency_string)
        return null
    # Register this trait to be encountered
    encoutered_traits.append(a_trait)

    # If receiver already has the given trait, return it immediatly, else try to instantiate it
    var trait_instance:Object = _traits_storage.get_trait_instance(receiver, a_trait)
    if not is_instance_valid(trait_instance):
        trait_instance = _instantiate_trait_for_receiver(a_trait, receiver, encoutered_traits)

    # This trait has been handled, so we can pop it out
    encoutered_traits.pop_back()

    return trait_instance

func _instantiate_trait_for_receiver(a_trait:Script, receiver:Object, encoutered_traits:Array[Script]) -> Object:
    assert(a_trait.can_instantiate(), "Trait '%s' can not be instantiated" % _traits_storage.get_trait_class_name(a_trait))

    # Trait constructor ('_init' method) can take 0 or multiple parameters.
    # If it takes parameters, it can either be:
    # - the object itself, since trait may need contextual usage to work
    # - a trait of the object itself
    var constructor_parameters:Array[Object] = []
    # To print a warning if the receiver is injected multiple times in the same constructor
    # Maybe something is wrong in that case...
    var receiver_object_already_injected:bool = false
    # Tells if there was a fatal error during trait instantiation
    var error_encountered:bool = false

    # Look for _init method to check if it takes parameters or not
    for method in a_trait.get_script_method_list():
        if method.name == "_init":
            print(method)
            # Find/construct required arguments
            for arg in method.args:
                # Is it the receiver itself, or a trait ?
                var constructor_argument_class_name:String = arg.class_name
                if constructor_argument_class_name.is_empty():
                    # Argument is not strongly typed. Just pass the receiver itself as parameter
                    # Hope for the best !
                    if receiver_object_already_injected:
                        printerr("⚠️ Injecting at least twice the trait receiver into trait '%s' constructor" % _traits_storage.get_trait_class_name(a_trait))
                    receiver_object_already_injected = true
                    constructor_parameters.append(receiver)
                else:
                    # Two possibilities :
                    # - parameter is an instance of the receiver itself : the receiver is the expected parameter
                    # - else, parameter is an instance of a trait, so try to get it or instantiate it
                    if _type_oracle.is_object_instance_of(constructor_argument_class_name, receiver):
                        constructor_parameters.append(receiver)
                    else:
                        var needed_trait:Script = _type_oracle.get_script_from_class_name(constructor_argument_class_name)
                        assert(is_instance_valid(needed_trait), "Trait '%s' can not be found in project." % constructor_argument_class_name)
                        var trait_instance:Object = _instantiate_trait(needed_trait, receiver, encoutered_traits)
                        assert(is_instance_valid(trait_instance), "Unable to instantiate trait '%s'." % constructor_argument_class_name)
                        if not is_instance_valid(trait_instance):
                            error_encountered = true
                            break
                        constructor_parameters.append(trait_instance)

            # Ugly but efficient: there is only one _init method in a script !
            break

    # Something went wrong, can not instantiate objects...
    if error_encountered:
        return null

    # Instantiate trait and save it into the receiver trait instances storage
    var trait_instance:Object = a_trait.new.callv(constructor_parameters)
    _traits_storage.store_trait_instance(receiver, trait_instance)

    # If trait has parent classes, to prevent to create new trait instance if parent classes are asked for this
    # receiver, register this trait instance has the one to be returned when a parent class is asked (POO style)
    var parent_script:Script = a_trait.get_base_script()
    while(parent_script != null):
        _traits_storage.store_trait_instance(receiver, trait_instance, parent_script)
        parent_script = parent_script.get_base_script()

    return trait_instance
