extends RefCounted
class_name GTraitsProjectSettings

##
## Project settings for traits.
##
## [color=red]This is an internal API.[/color]

#------------------------------------------
# Constants
#------------------------------------------

# Key to store the GTraitsRegistry autoload into settings
const _PROJECT_SETTINGS_GTRAITS_REGISTRY_AUTOLOAD:String = "autoload/GTraitsRegistry"

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
static var _instance:GTraitsProjectSettings

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsProjectSettings] instance
static func get_instance() -> GTraitsProjectSettings:
    if _instance == null:
        _instance = GTraitsProjectSettings.new()
    return _instance

## Declare or update [code]GTraitsRegistry[/code] autoload autoload in Project Settings
func update_gtraits_registry_autoload() -> void:
    # The star '*' means Autoload enabled"
    var autoload_path:String = "*%s" % GTraitsEditorSettings.get_instance().get_gtraits_registry_helper_output_path()
    var previous_autoload_path:String = ProjectSettings.get_setting(_PROJECT_SETTINGS_GTRAITS_REGISTRY_AUTOLOAD, "")
    if previous_autoload_path != autoload_path:
        ProjectSettings.set_setting(_PROJECT_SETTINGS_GTRAITS_REGISTRY_AUTOLOAD, autoload_path)
        ProjectSettings.save()

#------------------------------------------
# Private functions
#------------------------------------------
