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

# Singleton
static var _instance

# To store and retrieve traits from/into receiver
var _traits_storage:GTraitsStorage = GTraitsStorage.new()
# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_trait_build")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsTypeOracle] singleton
static func get_instance() -> GTraitsTraitBuilder:
    if _instance == null:
        _instance = GTraitsTraitBuilder.new()
    return _instance

## Retuns the trait for the given receiver. If the trait already exists, it is just returned. Otherwise,
## it is instantiated, registered into the receiver and returned.
func instantiate_trait(a_trait:Script, receiver:Object) -> Object:
    return _instantiate_trait(a_trait, receiver)

#------------------------------------------
# Private functions
#------------------------------------------

func _instantiate_trait(a_trait:Script, receiver:Object, encoutered_traits:Array[Script] = []) -> Object:
    # Check if this is an actual trait
    if not GTraitsTraitRegistry.get_instance().is_trait(a_trait):
        assert(false, "⚠️ Type '%s' is not a trait and can not be automatically instantiated" % GTraitsTypeOracle.get_instance().get_script_class_name(a_trait))
        return null

    # Check there is no cyclic dependencies in progress
    if encoutered_traits.has(a_trait):
        var cyclic_dependency_string:String = encoutered_traits \
            .map(GTraitsTypeOracle.get_instance().get_script_class_name) \
            .reduce(func(accum, name): return "%s -> %s" % [accum, name])
        cyclic_dependency_string = "%s -> %s" % [cyclic_dependency_string, GTraitsTypeOracle.get_instance().get_script_class_name(a_trait)]
        assert(false, "⚠️ Cyclic dependency detected during trait instantiation: %s" % cyclic_dependency_string)
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
    assert(a_trait.can_instantiate(), "⚠️ Trait '%s' can not be instantiated" % _traits_storage.get_trait_class_name(a_trait))

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

    var initializers:Dictionary = _extract_initialization_method_prototypes(a_trait)
    # There are multiple possibilities here:
    # - there is only one initializer, the _init method, with or without args: it's okay, only if this trait
    # is not a scene trait
    # - there is only one initializer, the _initialize method, with or without args: it's okay
    # - there are 2 initializers: it's okay if the _init one do not take any arguments
    var init_initializer:TraitInitializerPrototype = initializers.get("_init", null)
    var initialize_initializer:TraitInitializerPrototype = initializers.get("_initialize", null)
    if GTraitsTraitRegistry.get_instance().is_scene_trait(a_trait) and init_initializer != null and init_initializer.has_parameters():
        assert(false, "⚠️ Scene trait can not declare parameters in their _init function (in trait '%s'). Use the _initialize function instead." % _traits_storage.get_trait_class_name(a_trait))
        return null
    if init_initializer != null and initialize_initializer != null and init_initializer.has_parameters() and initialize_initializer.has_parameters():
        assert(false, "⚠️ Both _init and _initialize functions are declared with parameters in trait '%s'. Can no instantiate trait." % _traits_storage.get_trait_class_name(a_trait))
        return null

    var arg_types:Array[TraitInitializerInitParameter]
    if init_initializer != null and init_initializer.has_parameters():
        arg_types = init_initializer.arg_types
    elif initialize_initializer != null and initialize_initializer.has_parameters():
        arg_types = initialize_initializer.arg_types
    # else: no arg, empty array

    for arg_type in arg_types:
        var arg:Object = arg_type.get_parameter_instance(receiver, encoutered_traits)
        if arg == null:
             # Something went wrong, can not instantiate objects...
            return null
        constructor_parameters.append(arg)

    # Instantiate trait and save it into the receiver trait instances storage
    # Check if trait is a Scene trait or a Script trait, to instantiate the scene itself or only the script
    var trait_instance:Object

    # Script trait
    if not GTraitsTraitRegistry.get_instance().is_scene_trait(a_trait):
        # First instantiate using the new. if the _init initializer exists with parameters, inject them
        if init_initializer != null and init_initializer.has_parameters():
            trait_instance = a_trait.new.callv(constructor_parameters)
        else:
            trait_instance = a_trait.new()
    # Scene trait
    else:
        var trait_scene_path:String = GTraitsTraitRegistry.get_instance().get_scene_trait_scene_path(a_trait)
        trait_instance = ResourceLoader.load(trait_scene_path, "PackedScene").instantiate()

    # Then, if there exists an _initialize initializer, call it (with parameters if needed)
    if initialize_initializer != null:
        if initialize_initializer.has_parameters():
            trait_instance._initialize.callv(constructor_parameters)
        else:
            trait_instance._initialize()
    # Finally, save the trait instance
    _traits_storage.store_trait_instance(receiver, trait_instance, a_trait)

    # If trait has parent classes, to prevent to create new trait instance if parent classes are asked for this
    # receiver, register this trait instance has the one to be returned when a parent class is asked (POO style)
    var parent_script:Script = a_trait.get_base_script()
    while(parent_script != null):
        _traits_storage.store_trait_instance(receiver, trait_instance, parent_script)
        parent_script = parent_script.get_base_script()

    return trait_instance

func _extract_initialization_method_prototypes(a_trait:Script) -> Dictionary:
    var prototypes:Dictionary

    for method in a_trait.get_script_method_list():
        # To print a warning if the receiver is injected multiple times in the same constructor
        # Maybe something is wrong in that case...
        var receiver_object_already_injected:bool = false

        if method.name == "_init" or method.name == "_initialize":
            var initializer:TraitInitializerPrototype = TraitInitializerPrototype.new()
            initializer.method_name = method.name

            # Find/construct required arguments
            for arg in method.args:
                # Is it the receiver itself, or a trait ?
                var constructor_argument_class_name:String = arg.class_name
                if constructor_argument_class_name.is_empty():
                    # Argument is not strongly typed. Just pass the receiver itself as parameter
                    # Hope for the best !
                    if receiver_object_already_injected:
                        _logger.warn(func(): return "⚠️ Injecting at least twice the trait receiver into trait '%s' constructor" % _traits_storage.get_trait_class_name(a_trait))
                    receiver_object_already_injected = true
                    initializer.arg_types.append(TraitInitializerAnyInitParameter.new())
                else:
                    initializer.arg_types.append(TraitInitializerTypedInitParameter.new(constructor_argument_class_name, GTraitsTypeOracle.get_instance().get_script_from_class_name(constructor_argument_class_name)))

            # Register the initializer
            prototypes[initializer.method_name] = initializer

    # If no initializer have been found, use the default one: the _init without args
    if prototypes.is_empty() == null:
        var default_initializer:TraitInitializerPrototype = TraitInitializerPrototype.new()
        default_initializer.method_name = "_init"
        prototypes[default_initializer.method_name] = default_initializer

    return prototypes

class TraitInitializerPrototype extends RefCounted:
    # Name of the initializer method
    var method_name:String
    # Init method argument types. The init callable will require an instance of each to be called
    var arg_types:Array[TraitInitializerInitParameter] = []

    func has_parameters() -> bool:
        return not arg_types.is_empty()

    func has_no_parameters() -> bool:
        return arg_types.is_empty()

# Base type for initalizer parameter types
# To be specialized with the type of param
class TraitInitializerInitParameter extends RefCounted:

    # Get an instance of the desired init param
    func get_parameter_instance(receiver:Object, encoutered_traits:Array[Script]) -> Object:
        assert(false, "This method should be overridden")
        return null

class TraitInitializerAnyInitParameter extends TraitInitializerInitParameter:
    func get_parameter_instance(receiver:Object, encoutered_traits:Array[Script]) -> Object:
        return receiver

class TraitInitializerTypedInitParameter extends TraitInitializerInitParameter:
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

            var trait_instance:Object = GTraitsTraitBuilder.get_instance()._instantiate_trait(param_type, receiver, encoutered_traits)
            if not is_instance_valid(trait_instance):
                assert(false, "⚠️ Unable to instantiate trait '%s'." % param_type_name)
                return null

            return trait_instance
