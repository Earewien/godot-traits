@tool
extends RefCounted
class_name GTraitsEditorSettings

##
## Editor settings for traits.
##
## [color=red]This is an internal API.[/color]

#------------------------------------------
# Constants
#------------------------------------------

# Prefix for editor settings keys
const _EDITOR_SETTINGS_KEY_PREFIX:String = "plugin/gtraits/"
# Editor settings key for helper output path
const _EDITOR_SETTINGS_HELPER_OUTPUT_PATH:String = "%s/gtraits_helper_path" % _EDITOR_SETTINGS_KEY_PREFIX
# Editor settings key for helper regeneration shortcut
const _EDITOR_SETTINGS_HELPER_SHORTCUT:String = "%s/gtraits_helper_shorcut" % _EDITOR_SETTINGS_KEY_PREFIX
# Editor settings for script indent type (tabs or spaces)
const _EDITOR_SETTINGS_INDENT_TYPE:String = "text_editor/behavior/indent/type"
# Editor settings for indent size when type is space
const _EDITOR_SETTINGS_INDENT_SIZE:String = "text_editor/behavior/indent/size"


# Editor setting infos for the helper output path
const _SETTINGS_HELPER_OUTPUT_PATH_INFOS:Dictionary = {
    "name": _EDITOR_SETTINGS_HELPER_OUTPUT_PATH,
    "type": TYPE_STRING,
    "hint": PROPERTY_HINT_DIR,
    "default_value": "res://gtraits/helper"
}

# Editor setting infos for the helper shortcut
# as a var and not a const due to Shortcut method call...
var _SETTINGS_HELPER_SHORTCUT_INFOS:Dictionary = {
    "name": _EDITOR_SETTINGS_HELPER_SHORTCUT,
    "default_value": _get_helper_regeneration_default_shortcut()
}

#------------------------------------------
# Signals
#------------------------------------------

## Emited when the path to the [GTraits] script has changed
signal on_trait_invoker_path_changed()
## Emitedwhen the editor indentation type has changed
signal on_editor_indent_type_changed()
## Emited when the editor indentation size has changed
signal on_editor_indent_size_changed()

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Public variables
#------------------------------------------

## Type of indentation used in the editor
enum IndentType {
    ## Indent using tabs
    TABS,
    ## Indent using spaces
    SPACES
}

#------------------------------------------
# Private variables
#------------------------------------------

# Singleton
static var _instance:GTraitsEditorSettings

# Cache editor settings
var _editor_settings:EditorSettings = EditorInterface.get_editor_settings()

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsEditorSettings] instance
static func get_instance() -> GTraitsEditorSettings:
    if _instance == null:
        _instance = GTraitsEditorSettings.new()
    return _instance

## Initialize settings when addon is starting-up
func initialize() -> void:
    if not _editor_settings.settings_changed.is_connected(_on_editor_settings_changed):
        _editor_settings.settings_changed.connect(_on_editor_settings_changed)
    _ensure_default_settings()

## Uninitialize settings when addon is shutting down
func uninitialize() -> void:
    if _editor_settings.settings_changed.is_connected(_on_editor_settings_changed):
        _editor_settings.settings_changed.disconnect(_on_editor_settings_changed)
    _instance = null

## Returns the absolute path to the trait invoker output folder
func get_gtraits_helper_output_path() -> String:
    var output_path:String = _get_setting_value(_SETTINGS_HELPER_OUTPUT_PATH_INFOS)
    return "%s/gtraits.gd" % output_path

func get_gtraits_helper_regeneration_shortcut() -> Shortcut:
    return _get_setting_value(_SETTINGS_HELPER_SHORTCUT_INFOS)

## Returns the type of indentation used by the editor. See [enum GTraitsEditorSettings.IndentType]
func get_editor_indent_type() -> IndentType:
    return IndentType.TABS if _editor_settings.get_setting(_EDITOR_SETTINGS_INDENT_TYPE) == 0 else  IndentType.SPACES

## Returns the number of spaces characters used to indent, when indent type is [enum GTraitsEditorSettings.IndentType]
func get_editor_indent_size() -> int:
    return  _editor_settings.get_setting(_EDITOR_SETTINGS_INDENT_SIZE)

#------------------------------------------
# Private functions
#------------------------------------------

func _on_editor_settings_changed() -> void:
    for setting_path in _editor_settings.get_changed_settings():
        if setting_path == _EDITOR_SETTINGS_HELPER_OUTPUT_PATH:
            on_trait_invoker_path_changed.emit()
        elif setting_path == _EDITOR_SETTINGS_INDENT_TYPE:
            on_editor_indent_type_changed.emit()
        elif setting_path == _EDITOR_SETTINGS_INDENT_SIZE:
            on_editor_indent_size_changed.emit()

func _ensure_default_settings() -> void:
    _create_setting_if_needed(_SETTINGS_HELPER_OUTPUT_PATH_INFOS)
    _create_setting_if_needed(_SETTINGS_HELPER_SHORTCUT_INFOS)

func _create_setting_if_needed(infos:Dictionary) -> void:
    var settings_key:String = infos['name']

    if not _editor_settings.has_setting(settings_key):
        _editor_settings.set_setting(settings_key, infos['default_value'])
        _editor_settings.set_initial_value(settings_key, infos['default_value'], true)
        if infos.has("type"):
            _editor_settings.add_property_info(infos)

func _get_setting_value(settings_info:Dictionary) -> Variant:
    return _editor_settings.get_setting(settings_info['name'])

func _get_helper_regeneration_default_shortcut() -> Shortcut:
    var shortcut: Shortcut = Shortcut.new()
    var event: InputEventKey = InputEventKey.new()
    event.device = -1
    event.ctrl_pressed = true
    event.alt_pressed = true
    event.keycode = KEY_U
    shortcut.events = [event]
    return shortcut
