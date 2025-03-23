@icon("res://addons/godot-traits/core/container/gtraits_container_icon.svg")
class_name GTraitsContainer
extends Node

##
## Trait containers allows to declare scene traits directly in [i]Godot Editor[/i].
##
## This kind of declaration does not replace code declaration using [code]GTraits[/code] autoload, it completes it for a
## specific usage: using export variables, signal connections and all awesome [i]Godot[/i] functionnalities from your scene traits.
## [br][br]
## Trait lifecycle is exactly the same as declaring the scene trait through code:[br]
## - The scene trait is instantiated,[br]
## - Then, if the scene trait declares an [code]_initialize[/code] function, it is called,[br]
## - Finally, the scene trait [code]_ready[/code] function is called.
## [br][br]
## See also [GTraitsContainer2D] and [GTraitsContainer3D] for specialized trait containers.
## [br][br]
## [b][color=red]Note that it's no recommanded to add and remove scene traits into this container at runtime: trait lifecycle
## is not guaranted. To manipulate traits at runtime, use the [code]GTraits[/code] autoload.[/color][/b]

#------------------------------------------
# Constants
#------------------------------------------

const _META_KEY_NOT_A_TRAIT: String = "__not_a_trait__"

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

func _init() -> void:
    _set_trait_container_type()

    # Allows to detect traits entering the container as child node
    # This callback is called before the trait _ready function and after it's _init function
    # so it's perfect to invoke the trait _initialize function
    child_order_changed.connect(_on_child_order_changed)
    # Children added to this container outside SceneTree are not yet declared as trait
    # So when this container is added to the scene tree, declare them as trait if needed
    tree_entered.connect(_on_child_order_changed)

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _set_trait_container_type() -> void:
    # Flagging this container as Node scene trait container. For trait storage at runtime
    set_meta(GTraitsStorage.META_KEY_CONTAINER_TYPE, "Node")

func _on_child_order_changed() -> void:
    # Check if the container is still in the tree
    if not is_inside_tree():
        return

    for child in get_children():
        # Check if invalid node is present or not
        if child.get_meta(_META_KEY_NOT_A_TRAIT, false):
            continue

        # Flag invalid node
        if not GTraitsTypeOracle.get_instance().is_trait(child.get_script()):
            assert(false, "⚠️ Invalid node added as child of trait container: node '%s' is not a trait. This node will be ignored" % child.name)
            child.set_meta(_META_KEY_NOT_A_TRAIT, true)
        # Handle real traits !
        else:
            _initialize_trait(child)

func _initialize_trait(a_trait_instance: Node) -> void:
    var receiver: Node = get_parent()
    var the_trait: Script = a_trait_instance.get_script()

    # Check for already initialized scene traits: if already initialized, just go
    # There is a corner case where the same trait has already been added through code: this is an error
    # GTraitsCore ensures unicity of traits per receiver, but declaring scene traits through editor is not safe
    # since the developper can do both: through editor and through code
    if GTraitsCore.is_a(the_trait, receiver):
        if GTraitsCore.as_a(the_trait, receiver) != a_trait_instance:
            assert(false, "⚠️ Trait '%s' has been added twice to receiver '%s': through GTraits by code and through trait container. This will conducts to unexpected behaviors." % [GTraitsTypeOracle.get_instance().get_trait_info(the_trait).trait_name, receiver.name])
            return

    # Initialize the trait instance if needed
    # It's safe to call multiple times the _initialize method through its initializer since
    # there is a check to enure that it will be done only once
    GTraitsTraitInitializerRegistry.get_instance() \
        .get_initialize_initializer(the_trait) \
        .invoke(GTraitsTraitBuilder.new(), receiver, a_trait_instance)

    # Save trait instance into the receiver trait instances storage
    var trait_storage: GTraitsStorage = GTraitsStorage.get_instance()
    trait_storage.store_trait_instance(receiver, a_trait_instance, the_trait)

    # If trait has parent classes, to prevent to create new trait instance if parent classes are asked for this
    # receiver, register this trait instance has the one to be returned when a parent class is asked (POO style)
    var parent_script: Script = the_trait.get_base_script()
    while (parent_script != null):
        trait_storage.store_trait_instance(receiver, a_trait_instance, parent_script)
        parent_script = parent_script.get_base_script()
