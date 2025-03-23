@tool
extends EditorPlugin
class_name GodotTraitsEditorPlugin

##
## Editor plugins for Godot Traits addon
##

static var _instance: GodotTraitsEditorPlugin
const _palette_command_key_regen_script = "gtraits/regenerate-gtraits-script"

# Logger
var _logger: GTraitsLogger = GTraitsLogger.new("gtraits_plugin")

## Returns the [GodotTraitsEditorPlugin] instance
static func get_instance() -> GodotTraitsEditorPlugin:
    return _instance

func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _instance = self
        GTraitsEditorSettings.get_instance().initialize()
        GTraitsHelperGenerator.get_instance().initialize()
        GTraitsFileSystem.get_instance().initialize() # Must be initialized after helper since it emits signals catched by the helper
        EditorInterface.get_command_palette().add_command(
            "Regenerate GTraits Script",
            _palette_command_key_regen_script,
            Callable(self, "regenerate_gtraits_script"),
            GTraitsEditorSettings.get_instance().get_gtraits_helper_regeneration_shortcut().get_as_text())
        _logger.info(func(): return "🎭 Godot Traits loaded !")

func _exit_tree() -> void:
    if Engine.is_editor_hint():
        EditorInterface.get_command_palette().remove_command(_palette_command_key_regen_script)
        GTraitsFileSystem.get_instance().uninitialize()
        GTraitsHelperGenerator.get_instance().uninitialize()
        GTraitsEditorSettings.get_instance().uninitialize()

        _instance = null
        _logger.info(func(): return "🎭 Godot Traits unloaded !")

func _unhandled_key_input(event: InputEvent) -> void:
    if Engine.is_editor_hint():
        if GTraitsEditorSettings.get_instance().get_gtraits_helper_regeneration_shortcut().matches_event(event):
            if event.is_released():
                _regenerate_gtraits_script()

func _regenerate_gtraits_script() -> void:
    GTraitsFileSystem.get_instance().force_full_scan(false)
    GTraitsHelperGenerator.get_instance().clear_and_regenerate()
    _logger.info(func(): return "🎭 Godot Traits: GTraits script regenerated in '%s'" % GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path())
