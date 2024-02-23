extends RefCounted
class_name GTraitsTraitInitializerRegistry

##
## Trait initializer method registry for [i]Godot Traits[/i].
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
static var _instance:GTraitsTraitInitializerRegistry

# _init functions registry: keys are Script, values are GTraitsTraitInitializer
var _init_func_registry:Dictionary
# _initialize functions registry: keys are Script, values are GTraitsTraitInitializer
var _initialize_func_registry:Dictionary
# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_trait_init_reg")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsTraitInitializerRegistry] singleton
static func get_instance() -> GTraitsTraitInitializerRegistry:
    if _instance == null:
        _instance = GTraitsTraitInitializerRegistry.new()
    return _instance

## Returns the [code]_init[/code] function initializer for the given trait. Never [code]null[/code]
func get_init_initializer(a_trait:Script) -> GTraitsTraitInitializer:
    var initializer:GTraitsTraitInitializer = _init_func_registry.get(a_trait)
    if initializer == null:
        _register_initialization_methods(a_trait)
        initializer = _init_func_registry.get(a_trait)
    return initializer

## Returns the [code]_initialize[/code] function initializer for the given trait. Never [code]null[/code]
func get_initialize_initializer(a_trait:Script) -> GTraitsTraitInitializer:
    var initializer:GTraitsTraitInitializer = _initialize_func_registry.get(a_trait)
    if initializer == null:
        _register_initialization_methods(a_trait)
        initializer = _initialize_func_registry.get(a_trait)
    return initializer

#------------------------------------------
# Private functions
#------------------------------------------

func _register_initialization_methods(a_trait:Script) -> void:
    var _init_initializer:GTraitsTraitInitializer
    var _initialize_initializer:GTraitsTraitInitializer

    for method in a_trait.get_script_method_list():
        # To print a warning if the receiver is injected multiple times in the same constructor
        # Maybe something is wrong in that case...
        var receiver_object_already_injected:bool = false

        if method.name == "_init" or method.name == "_initialize":
            var initializer:GTraitsTraitInitializer = GTraitsTraitInitializer.new(method.name, a_trait)

            # Find/construct required arguments
            for arg in method.args:
                # Is it the receiver itself, or a trait ?
                var constructor_argument_class_name:String = arg.class_name
                if constructor_argument_class_name.is_empty():
                    # Argument is not strongly typed. Just pass the receiver itself as parameter
                    # Hope for the best !
                    if receiver_object_already_injected:
                        _logger.warn(func(): return "⚠️ Injecting at least twice the trait receiver into trait '%s' constructor" % GTraitsTypeOracle.get_instance().get_trait_info(a_trait).trait_name)
                    receiver_object_already_injected = true
                    initializer.parameter_types.append(GTraitsTraitInitializer.AnyParameter.new())
                else:
                    initializer.parameter_types.append(GTraitsTraitInitializer.TypedParameter.new( \
                        constructor_argument_class_name, \
                        GTraitsTypeOracle.get_instance().get_script_from_class_name(constructor_argument_class_name)))

            if initializer.name == "_init":
                _init_initializer = initializer
            else:
                _initialize_initializer = initializer

    # Initializers should never be null, for simplicity
    if _init_initializer == null:
        _init_initializer = GTraitsTraitInitializer.new("_init", a_trait)
    if _initialize_initializer == null:
        _initialize_initializer = GTraitsTraitInitializer.new("_initialize", a_trait, false)

    # Register them
    _init_func_registry[a_trait] = _init_initializer
    _initialize_func_registry[a_trait] = _initialize_initializer
