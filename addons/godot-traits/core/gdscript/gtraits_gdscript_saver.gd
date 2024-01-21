extends RefCounted
class_name GTraitsGDScriptSaver

##
## GDScript resource saver for [GTraits].
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

# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_trait_build")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Saves script code into a file and returns the created [Script] instance.
## If the script already exists, content is replaced.
func save(script_path:String, script_content:String) -> Script:
    var script:Script = _get_or_create_script(script_path)

    # Change script content and save it
    script.source_code = script_content

    # If this script is currently beeing edited in Godot Engine Script Editor,
    # replace the editor content with the new script content
    # A bit hacky, but I don't know how to do it better, editor seems to not reload automatically
    for opened_editor in EditorInterface.get_script_editor().get_open_script_editors():
        if opened_editor.get_meta("_edit_res_path", "") == script.resource_path:
            opened_editor.get_base_editor().text = script_content
            break

    # Save it to FS
    _do_save_script(script, script_path)
    # Emit that script has changed
    script.reload(false)
    script.emit_changed()

    return script

#------------------------------------------
# Private functions
#------------------------------------------

func _get_or_create_script(script_path:String) -> Script:
    var script:Script

    if FileAccess.file_exists(script_path):
        script = load(script_path)
    else:
        script = GDScript.new()
        _do_save_script(script, script_path)

    return script

func _do_save_script(script:Script, script_path:String) -> void:
    script.resource_path = script_path
    DirAccess.make_dir_recursive_absolute(script.resource_path.get_base_dir())
    var error = ResourceSaver.save(script, script.resource_path, ResourceSaver.FLAG_CHANGE_PATH)
    if error != OK:
        _logger.warn(func(): return "⚠️ Unable to save script content into '%s': %s" % [script.resource_path, error_string(error)])
