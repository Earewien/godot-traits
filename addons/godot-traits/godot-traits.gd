@tool
extends EditorPlugin
class_name GodotTraitsEditorPlugin

##
## Editor plugins for Godot Traits addon
##

static var _instance:GodotTraitsEditorPlugin
const commandKey_RegenGTraitsScript = "gtraits/regenerate-gtraits-script"

# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_plugin")

## Returns the [GodotTraitsEditorPlugin] instance
static func get_instance() -> GodotTraitsEditorPlugin:
    return _instance

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _instance = self
        GTraitsFileSystem.get_instance().initialize()
        GTraitsEditorSettings.get_instance().initialize()
        GTraitsHelperGenerator.get_instance().initialize()
        EditorInterface.get_command_palette().add_command(
            "Regenerate GTraits Script",
            commandKey_RegenGTraitsScript,
            Callable(self, "regenerate_gtraits_script"),
            GTraitsEditorSettings.get_instance().get_gtraits_helper_regeneration_shortcut().get_as_text())
        _logger.info(func(): return "🎭 Godot Traits loaded !")

func _exit_tree() -> void:
    if Engine.is_editor_hint():
        EditorInterface.get_command_palette().remove_command(commandKey_RegenGTraitsScript)
        GTraitsHelperGenerator.get_instance().uninitialize()
        GTraitsEditorSettings.get_instance().uninitialize()
        GTraitsFileSystem.get_instance().uninitialize()
        _instance = null
        _logger.info(func(): return "🎭 Godot Traits unloaded !")

func _unhandled_key_input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        if GTraitsEditorSettings.get_instance().get_gtraits_helper_regeneration_shortcut().matches_event(event):
            if event.is_released():
                regenerate_gtraits_script()

func regenerate_gtraits_script():
    GTraitsFileSystem.get_instance().force_full_scan()
    GTraitsHelperGenerator.get_instance().clear_and_regenerate()
    _logger.info(func(): return "🎭 Godot Traits: GTraits script regenerated in '%s'" % GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path())
