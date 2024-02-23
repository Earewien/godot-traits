extends RefCounted
class_name GTraitsTraitBuilder

##
## Trait builder for [i]Godot Traits[/i].
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

# All traits encountered during trait instantiation. For cyclic dependencies detection
var _encoutered_traits:Array[Script]
# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_trait_build")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Retuns the trait for the given receiver. If the trait already exists, it is just returned. Otherwise,
## it is instantiated, registered into the receiver and returned.
func instantiate_trait(a_trait:Script, receiver:Object) -> Object:
    return _instantiate_trait(a_trait, receiver)

#------------------------------------------
# Private functions
#------------------------------------------

func _instantiate_trait(a_trait:Script, receiver:Object) -> Object:
    # Check if this is an actual trait
    if not GTraitsTypeOracle.get_instance().is_trait(a_trait):
        assert(false, "⚠️ Type '%s' is not a trait and can not be automatically instantiated" % GTraitsTypeOracle.get_instance().get_script_class_name(a_trait))
        return null

    # Check there is no cyclic dependencies in progress
    if _encoutered_traits.has(a_trait):
        var cyclic_dependency_string:String = _encoutered_traits \
            .map(func(sc): return GTraitsTypeOracle.get_instance().get_trait_info(sc).trait_name) \
            .reduce(func(accum, name): return "%s -> %s" % [accum, name])
        cyclic_dependency_string = "%s -> %s" % [cyclic_dependency_string,GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name]
        assert(false, "⚠️ Cyclic dependency detected during trait instantiation: %s" % cyclic_dependency_string)
        return null
    # Register this trait to be encountered
    _encoutered_traits.append(a_trait)

    # If receiver already has the given trait, return it immediatly, else try to instantiate it
    var trait_instance:Object = GTraitsStorage.get_instance().get_trait_instance(receiver, a_trait)
    if not is_instance_valid(trait_instance):
        trait_instance = _instantiate_trait_for_receiver(a_trait, receiver)

    # This trait has been handled, so we can pop it out
    _encoutered_traits.pop_back()

    return trait_instance

func _instantiate_trait_for_receiver(a_trait:Script, receiver:Object) -> Object:
    var trait_info:GTraitsTypeOracle.TraitInfo = GTraitsTypeOracle.get_instance().get_trait_info(a_trait)
    assert(trait_info != null, "Should never occur !")
    assert(a_trait.can_instantiate(), "⚠️ Trait '%s' can not be instantiated" % trait_info.trait_name)

    # There are multiple possibilities here:
    # - there is only one initializer, the _init method, with or without args: it's okay, only if this trait
    # is not a scene trait
    # - there is only one initializer, the _initialize method, with or without args: it's okay
    # - there are 2 initializers: it's okay if the _init one do not take any arguments
    var init_initializer:GTraitsTraitInitializer = GTraitsTraitInitializerRegistry.get_instance().get_init_initializer(a_trait)
    var initialize_initializer:GTraitsTraitInitializer = GTraitsTraitInitializerRegistry.get_instance().get_initialize_initializer(a_trait)
    if trait_info.is_scene_trait() and init_initializer.has_parameters():
        assert(false, "⚠️ Scene trait can not declare parameters in their _init function (in trait '%s'). Use the _initialize function instead." % trait_info.trait_name)
        return null
    if initialize_initializer.exists and init_initializer.has_parameters() and initialize_initializer.has_parameters():
        assert(false, "⚠️ Both _init and _initialize functions are declared with parameters in trait '%s'. Can no instantiate trait." % trait_info.trait_name)
        return null

    # Instantiate trait and save it into the receiver trait instances storage
    var trait_storage:GTraitsStorage = GTraitsStorage.get_instance()
    var trait_instance:Object = init_initializer.invoke(self, receiver, null)
    trait_instance = initialize_initializer.invoke(self, receiver, trait_instance)
    trait_storage.store_trait_instance(receiver, trait_instance, a_trait)

    # If trait has parent classes, to prevent to create new trait instance if parent classes are asked for this
    # receiver, register this trait instance has the one to be returned when a parent class is asked (POO style)
    var parent_script:Script = a_trait.get_base_script()
    while(parent_script != null):
        trait_storage.store_trait_instance(receiver, trait_instance, parent_script)
        parent_script = parent_script.get_base_script()

    # Store trait into a container, if needed
    trait_storage.add_trait_to_container(receiver, trait_instance)

    return trait_instance
