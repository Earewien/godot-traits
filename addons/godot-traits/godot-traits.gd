@tool
extends EditorPlugin
class_name GodotTraitsEditorPlugin

##
## Editor plugins for Godot Traits addon
##

static var _instance:GodotTraitsEditorPlugin

## Returns the [GodotTraitsEditorPlugin] instance
static func get_instance() -> GodotTraitsEditorPlugin:
    return _instance

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _instance = self
        GTraitsEditorSettings.get_instance().initialize()
        GTraitsHelperGenerator.get_instance().initialize()
        print("🎭 Godot Traits loaded !")

func _exit_tree() -> void:
    if Engine.is_editor_hint():
        GTraitsHelperGenerator.get_instance().uninitialize()
        GTraitsEditorSettings.get_instance().uninitialize()
        _instance = null
        print("🎭 Godot Traits unloaded !")

func _unhandled_key_input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        if GTraitsEditorSettings.get_instance().get_gtraits_helper_regeneration_shortcut().matches_event(event):
            if event.is_released():
                GTraitsHelperGenerator.get_instance().clear_and_regenerate()
                print("🎭 Godot Traits: GTraits script regenerated in '%s'" % GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path())
