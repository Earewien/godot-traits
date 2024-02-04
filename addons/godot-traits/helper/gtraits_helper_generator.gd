extends RefCounted
class_name GTraitsHelperGenerator

##
## [i]Godot Traits[/i] helper generator.
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
static var _instance:GTraitsHelperGenerator

# Path to generated [code]GTraits[/code] autoload script
var _gtraits_script_path:String
# Parser to get script information
var _gdscript_parser:GTraitsGDScriptParser = GTraitsGDScriptParser.new()
# Allows to save script content into a file
var _gdscript_saver:GTraitsGDScriptSaver = GTraitsGDScriptSaver.new()
# All known traits order by script path, keys are script paths, values are dictionaries of traits
# in those scripts, where keys are trait qualified names and values are GTraitsGDScriptParser.ClassInfo
var _traits_by_scripts:Dictionary
# Script paths which are script root of a scene in the project. Keys are script paths, and values are
# arrays of scene paths since a script may be the root script of multiple scenes
var _scene_paths_by_script_path:GTraitsHash = GTraitsHash.new()

# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_helper_gen")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsHelperGenerator] instance
static func get_instance() -> GTraitsHelperGenerator:
    if _instance == null:
        _instance = GTraitsHelperGenerator.new()
    return _instance

func initialize() -> void:
    var editor_settings:GTraitsEditorSettings = GTraitsEditorSettings.get_instance()
    _gtraits_script_path = editor_settings.get_gtraits_helper_output_path()
    if not editor_settings.on_trait_invoker_path_changed.is_connected(_on_trait_invoker_path_changed):
        editor_settings.on_trait_invoker_path_changed.connect(_on_trait_invoker_path_changed)
    if not editor_settings.on_editor_indent_type_changed.is_connected(_on_editor_indent_type_changed):
        editor_settings.on_editor_indent_type_changed.connect(_on_editor_indent_type_changed)
    if not editor_settings.on_editor_indent_size_changed.is_connected(_on_editor_indent_size_changed):
        editor_settings.on_editor_indent_size_changed.connect(_on_editor_indent_size_changed)

    var filesystem:GTraitsFileSystem = GTraitsFileSystem.get_instance()
    if not filesystem.on_scripts_changed.is_connected(_on_scripts_changed):
        filesystem.on_scripts_changed.connect(_on_scripts_changed)
    if not filesystem.on_scripts_removed.is_connected(_on_scripts_removed):
        filesystem.on_scripts_removed.connect(_on_scripts_removed)
    if not filesystem.on_scenes_changed.is_connected(_on_scenes_changed):
        filesystem.on_scenes_changed.connect(_on_scenes_changed)
    if not filesystem.on_scenes_removed.is_connected(_on_scenes_removed):
        filesystem.on_scenes_removed.connect(_on_scenes_removed)

    _logger.info(func(): return "Generating GTraits helper on editor startup")
    _reload_scripts_traits_from_filesystem()

func uninitialize() -> void:
    var editor_settings:GTraitsEditorSettings = GTraitsEditorSettings.get_instance()
    if editor_settings.on_trait_invoker_path_changed.is_connected(_on_trait_invoker_path_changed):
        editor_settings.on_trait_invoker_path_changed.disconnect(_on_trait_invoker_path_changed)
    if editor_settings.on_editor_indent_type_changed.is_connected(_on_editor_indent_type_changed):
        editor_settings.on_editor_indent_type_changed.disconnect(_on_editor_indent_type_changed)
    if editor_settings.on_editor_indent_size_changed.is_connected(_on_editor_indent_size_changed):
        editor_settings.on_editor_indent_size_changed.disconnect(_on_editor_indent_size_changed)

    var filesystem:GTraitsFileSystem = GTraitsFileSystem.get_instance()
    if filesystem.on_scripts_changed.is_connected(_on_scripts_changed):
        filesystem.on_scripts_changed.disconnect(_on_scripts_changed)
    if filesystem.on_scripts_removed.is_connected(_on_scripts_removed):
        filesystem.on_scripts_removed.disconnect(_on_scripts_removed)
    if filesystem.on_scenes_changed.is_connected(_on_scenes_changed):
        filesystem.on_scenes_changed.disconnect(_on_scenes_changed)
    if filesystem.on_scenes_removed.is_connected(_on_scenes_removed):
        filesystem.on_scenes_removed.disconnect(_on_scenes_removed)

    _instance = null

## Force [code]GTraits[/code] autoload script regeneration by rescanning all script in [code]res://[/code] folder.
func clear_and_regenerate() -> void:
    _reload_scripts_traits_from_filesystem()

#------------------------------------------
# Private functions
#------------------------------------------

func _on_trait_invoker_path_changed() -> void:
    var old_gtraits_path:String = _gtraits_script_path
    _gtraits_script_path = GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path()

    if FileAccess.file_exists(old_gtraits_path):
        # Quite complicated to avoid editor to be lost...
        # First, load old script to put in into memory
        var gtrait_script:Script = load(old_gtraits_path)
        # Then delete it from filesystem. Trick is : Godot Editor can not see this deletion
        # So we will run a FS scan, in order to make Godot Editor aware of this file deletion
        DirAccess.remove_absolute(old_gtraits_path)
        _scan_filesystem()

        # Now, FS has been scanned, so it's safe to save the script at its new location
        gtrait_script.resource_path = _gtraits_script_path
        DirAccess.make_dir_recursive_absolute(_gtraits_script_path.get_base_dir())
        ResourceSaver.save(gtrait_script, gtrait_script.resource_path)
        GTraitsProjectSettings.get_instance().update_gtraits_autoload()
    else:
        _generate_gtraits_helper()

func _scan_filesystem() -> void:
    var rss_filesystem: EditorFileSystem = EditorInterface.get_resource_filesystem()
    var godot_scene_tree:SceneTree = EditorInterface.get_base_control().get_tree()
    rss_filesystem.scan_sources()
    while rss_filesystem.is_scanning():
        await godot_scene_tree.create_timer(0.1).timeout

func _reload_scripts_traits_from_filesystem() -> void:
    _traits_by_scripts.clear()
    _on_scenes_changed(GTraitsFileSystem.get_instance().get_scenes())
    _on_scripts_changed(GTraitsFileSystem.get_instance().get_scripts())

func _on_editor_indent_type_changed() -> void:
    _logger.info(func(): return "Generating GTraits helper on editor setting indent type changed")
    _generate_gtraits_helper()

func _on_editor_indent_size_changed() -> void:
    _logger.info(func(): return "Generating GTraits helper on editor setting indent size changed")
    _generate_gtraits_helper()

func _on_scripts_changed(scripts:Array) -> void:
    if not scripts.is_empty():
        var has_changes:bool = false
        for script in scripts:
            if script.script_path != GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path():
                _handle_script_changed(script, false)
                has_changes = true
        if has_changes:
            _generate_gtraits_helper()

func _on_scripts_removed(scripts:Array) -> void:
    var previous_known_script_count:int = _traits_by_scripts.size()
    for script in scripts:
        _traits_by_scripts.erase(script.script_path)
    if previous_known_script_count != _traits_by_scripts.size():
        _generate_gtraits_helper()

func _on_scenes_changed(scenes:Array) -> void:
    if not scenes.is_empty():
        var has_changes:bool = false
        for scene in scenes:
            var old_scene_script_path = _scene_paths_by_script_path.get_key(scene.packed_scene_path)
            if scene.has_script():
                if scene.script_info.script_path != old_scene_script_path:
                    _scene_paths_by_script_path.erase_value(scene.packed_scene_path)
                    _scene_paths_by_script_path.put_value(scene.script_info.script_path, scene.packed_scene_path)
                    has_changes = true
            else:
                if old_scene_script_path != null:
                    _scene_paths_by_script_path.erase_value(scene.packed_scene_path)
                    has_changes = true

        if has_changes:
            _generate_gtraits_helper()

func _on_scenes_removed(scenes:Array) -> void:
    if not scenes.is_empty():
        var has_changes:bool = false
        for scene in scenes:
            var scene_script_path = _scene_paths_by_script_path.erase_value(scene.packed_scene_path)
            if scene_script_path != null && _traits_by_scripts.has(scene_script_path):
                has_changes = true

        if has_changes:
            _generate_gtraits_helper()

func _handle_script_changed(script_info:GTraitsFileSystem.ScriptInfo, allow_generate:bool = false) -> void:
    var traits:Dictionary = _get_script_traits(script_info)

    var changed:bool = false
    if traits.is_empty() and _traits_by_scripts.has(script_info.script_path):
        _traits_by_scripts.erase(script_info.script_path)
        changed = true
    elif not traits.is_empty():
        changed = true
        _traits_by_scripts[script_info.script_path] = traits

    if allow_generate and changed:
        _generate_gtraits_helper()

func _get_script_traits(script_info:GTraitsFileSystem.ScriptInfo) -> Dictionary:
    var traits:Dictionary = { }
    for class_info in script_info.class_info:
        if class_info.annotations.has("trait"):
            traits[class_info.qualified_class_name] = class_info

    # If there are traits but they can not be accessed, display a warning into the editor
    # Those traits will not have helper methods
    if not traits.is_empty() and not script_info.has_top_level_class():
        traits.clear()
        _logger.warn(func(): return "⚠️ Script '%s' does not have a top level class (declared by class_name keyword) but \
            contains traits. As a consequence, hey will not be available outside this script. (in script '%s')" % [script_info.script_file_name, script_info.script_path])

    return traits

func _generate_gtraits_helper() -> void:
    _logger.info(func(): return "Generating GTraits helper due to changes")

    # Before generating GTraits script, ensure that all references scripts are still available
    # some may have been deleted from outside Godot Editor
    # Do it in 2 passes since it's not supported to erase values from a dictionary while iterating
    var scripts_to_remove:PackedStringArray = []
    for script_path in _traits_by_scripts:
        if not FileAccess.file_exists(script_path):
            scripts_to_remove.append(script_path)
    for script_path in scripts_to_remove:
        _traits_by_scripts.erase(script_path)

    # Same for scenes
    var scenes_to_remove:PackedStringArray = []
    for scene_path in _scene_paths_by_script_path.values():
        if not FileAccess.file_exists(scene_path):
            scenes_to_remove.append(scene_path)
    for scene_path in scenes_to_remove:
        _scene_paths_by_script_path.erase_value(scene_path)

    # Then proceed to generation
    var indent_string:String = _get_indent_string()

    # Be predictable for script content : do not depend on parse order
    var sorted_script_paths:Array = _traits_by_scripts.keys()
    sorted_script_paths.sort()

    var content:String = ''
    content += "# ##########################################################################\n"
    content += "# This file is auto generated and should ne be edited !\n"
    content += "# It can safely be committed to your VCS.\n"
    content += "# This script is automatically declared as singleton in your\n"
    content += "# Project Settings. Do not remove it or disable it or GTraits will not\n"
    content += "# work as expected\n"
    content += "# ##########################################################################\n"
    content += "\n"
    content += "extends Node\n"
    content += "\n"
    content += "## \n"
    content += "## Auto-generated utility to handle traits in Godot.\n"
    content += "## \n"
    content += "\n"
    content += "#region Trait declaration\n\n"
    if not _traits_by_scripts.is_empty():
        content += "static func _static_init() -> void:\n"
        for script_path in sorted_script_paths:
            var traits = _traits_by_scripts[script_path]

            # Be predictable for script content : do not depend on parse order
            var sorted_trait_qualified_names:Array = traits.keys()
            sorted_trait_qualified_names.sort()

            for qualified_trait_name in sorted_trait_qualified_names:
                var the_trait:GTraitsGDScriptParser.ClassInfo = traits[qualified_trait_name]
                if _scene_paths_by_script_path.has_key(the_trait.script_path):
                    var scene_paths:Array = _scene_paths_by_script_path.get_values(the_trait.script_path)
                    if scene_paths.size() == 1:
                        content += indent_string + "GTraitsCore.register_trait(%s, \"%s\", \"%s\")\n" % [the_trait.qualified_class_name, the_trait.qualified_class_name, scene_paths.front()]
                    else:
                        _logger.warn(func(): return "⚠️ Multiple scenes are using script trait '%s' as root script. It will not be declared as a Scene trait." % the_trait.qualified_class_name)
                        content += indent_string + "GTraitsCore.register_trait(%s, \"%s\")\n" % [the_trait.qualified_class_name, the_trait.qualified_class_name]
                else:
                    content += indent_string + "GTraitsCore.register_trait(%s, \"%s\")\n" % [the_trait.qualified_class_name, the_trait.qualified_class_name]

    content += "\n"
    content += "#endregion\n"
    content += "\n"
    content += "#region Core methods\n\n"
    content += "## Shortcut for [method GTraitsCore.as_a]\n"
    content += "static func as_a(a_trait:Script, object:Object) -> Object:\n"
    content += indent_string + "return GTraitsCore.as_a(a_trait, object)\n"
    content += "\n"
    content += "## Shortcut for [method GTraitsCore.is_a]\n"
    content += "static func is_a(a_trait:Script, object:Object) -> bool:\n"
    content += indent_string + "return GTraitsCore.is_a(a_trait, object)\n"
    content += "\n"
    content += "## Shortcut for [method GTraitsCore.add_trait_to]\n"
    content += "static func add_trait_to(a_trait:Script, object:Object) -> Object:\n"
    content += indent_string + "return GTraitsCore.add_trait_to(a_trait, object)\n"
    content += "\n"
    content += "## Shortcut for [method GTraitsCore.remove_trait_from]\n"
    content += "static func remove_trait_from(a_trait:Script, object:Object) -> void:\n"
    content += indent_string + "GTraitsCore.remove_trait_from(a_trait, object)\n"
    content += "\n"
    content += "## Shortcut for [method GTraitsCore.if_is_a]\n"
    content += "static func if_is_a(a_trait:Script, object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:\n"
    content += indent_string + "return GTraitsCore.if_is_a(a_trait, object, if_callable, deferred_call)\n"
    content += "\n"
    content += "## Shortcut for [method GTraitsCore.if_is_a_or_else]\n"
    content += "static func if_is_a_or_else(a_trait:Script, object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:\n"
    content += indent_string + "return GTraitsCore.if_is_a_or_else(a_trait, object, if_callable, else_callable, deferred_call)\n"
    content += "\n"
    content += "#endregion\n"
    content += "\n"
    var generated_traits:PackedStringArray = []

    for script_path in sorted_script_paths:
        var traits = _traits_by_scripts[script_path]

        # Be predictable for script content : do not depend on parse order
        var sorted_trait_qualified_names:Array = traits.keys()
        sorted_trait_qualified_names.sort()

        for qualified_trait_name in sorted_trait_qualified_names:
            var the_trait:GTraitsGDScriptParser.ClassInfo = traits[qualified_trait_name]

            var trait_full_name:String = the_trait.qualified_class_name
            var trait_name_alias:String = the_trait.annotations['trait'].options['alias'] if the_trait.annotations['trait'].options.has("alias") else ''
            if not trait_name_alias.is_empty() and generated_traits.has(trait_name_alias):
                _logger.warn(func(): return "⚠️ Trait '%s' can not use alias '%s' since another trait already uses this name or this alias. It's original name will be used. (in script '%s')" % [trait_full_name, trait_name_alias, script_path])
                trait_name_alias = ''

            var snaked_trait_full_name = trait_full_name.replace('.', '').to_snake_case()
            var snaked_trait_name_alias = trait_name_alias.replace('.', '').to_snake_case()

            content += "#region Trait %s\n" % trait_full_name
            content += "# Trait script path: '%s'\n" % script_path
            if trait_name_alias.is_empty():
                content += "\n\n"
                content += "## Get [%s] trait from the given object. Raise an assertion error if trait is not found.\n" % trait_full_name
                content += "## See [method GTraits.as_a] for more details.\n"
                content += "static func as_%s(object:Object) -> %s:\n" % [snaked_trait_full_name, trait_full_name]
                content += indent_string + "return as_a(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Gets if the given object is a [%s].\n" % trait_full_name
                content += "## See [method GTraits.is_a] for more details.\n"
                content += "static func is_%s(object:Object) -> bool:\n" % snaked_trait_full_name
                content += indent_string + "return is_a(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Add trait [%s] to the given object.\n" % trait_full_name
                content += "## See [method GTraits.add_trait_to] for more details.\n"
                content += "static func set_%s(object:Object) -> %s:\n" % [snaked_trait_full_name, trait_full_name]
                content += indent_string + "return add_trait_to(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Remove trait [%s] from the given object. Removed trait instance is automatically freed.\n" % trait_full_name
                content += "## See [method GTraits.remove_trait_from] for more details.\n"
                content += "static func unset_%s(object:Object) -> void:\n" % snaked_trait_full_name
                content += indent_string + "remove_trait_from(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Calls the given [Callable] if and only if an object is a [%s]. The callable.\n" % trait_full_name
                content += "## takes the [%s] trait as argument. Returns the callable result if the object is a\n" % trait_full_name
                content += "## [%s], [code]null[/code] otherwise.\n" % trait_full_name
                content += "## [br][br]\n"
                content += "## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and\n"
                content += "## the returned value will always be [code]null[/code].\n"
                content += "## [br][br]\n"
                content += "## See [method GTraits.if_is_a] for more details.\n"
                content += "static func if_is_%s(object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:\n" % snaked_trait_full_name
                content += indent_string + "return if_is_a(%s, object, if_callable, deferred_call)\n" % trait_full_name
                content += "\n"
                content += "## Calls the given [i]if[/i] [Callable] if and only if an object is a [%s], or else calls\n" % trait_full_name
                content += "## the given [i]else[/i] callable. The [i]if[/i] callable takes the [%s] trait as argument, and the\n" % trait_full_name
                content += "## [i]else[/i] callable does not take any argument. Returns the called callable result..\n"
                content += "## [br][br]\n"
                content += "## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and\n"
                content += "## the returned value will always be [code]null[/code].\n"
                content += "## [br][br]\n"
                content += "## See [method GTraits.if_is_a_or_else] for more details.\n"
                content += "static func if_is_%s_or_else(object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:\n" % snaked_trait_full_name
                content += indent_string + "return if_is_a_or_else(%s, object, if_callable, else_callable, deferred_call)\n" % trait_full_name
                content += "\n"
            else:
                content += "# Trait %s is configured to be accessed by alias %s" % [trait_full_name, trait_name_alias]
                content += "\n\n"
                content += "## Get [%s] as trait alias [b]%s[/b] trait from the given object. Raise an assertion error if trait is not found.\n" % [trait_full_name, trait_name_alias]
                content += "## See [method GTraits.as_a] for more details.\n"
                content += "static func as_%s(object:Object) -> %s:\n" % [snaked_trait_name_alias, trait_full_name]
                content += indent_string + "return as_a(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Gets if the given object is a [%s] as trait alias [b][%s][/b].\n" % [trait_full_name, trait_name_alias]
                content += "## See [method GTraits.is_a] for more details.\n"
                content += "static func is_%s(object:Object) -> bool:\n" %snaked_trait_name_alias
                content += indent_string + "return is_a(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Add trait [%s] as trait alias [b]%s[/b] to the given object.\n" % [trait_full_name, trait_name_alias]
                content += "## See [method GTraits.add_trait_to] for more details.\n"
                content += "static func set_%s(object:Object) -> %s:\n" % [snaked_trait_name_alias, trait_full_name]
                content += indent_string + "return add_trait_to(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Remove trait [%s] as trait alias [b]%s[/b] from the given object. Removed trait instance is automatically freed.\n" % [trait_full_name, trait_name_alias]
                content += "## See [method GTraits.remove_trait_from] for more details.\n"
                content += "static func unset_%s(object:Object) -> void:\n" % snaked_trait_name_alias
                content += indent_string + "remove_trait_from(%s, object)\n" % trait_full_name
                content += "\n"
                content += "## Calls the given [Callable] if and only if an object is a [%s] as trait alias [b]%s[/b]. The callable.\n" % [trait_full_name, trait_name_alias]
                content += "## takes the [%s] trait as argument. Returns the callable result if the object is a\n" % trait_full_name
                content += "## [%s], [code]null[/code] otherwise.\n" % trait_full_name
                content += "## [br][br]\n"
                content += "## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and\n"
                content += "## the returned value will always be [code]null[/code].\n"
                content += "## [br][br]\n"
                content += "## See [method GTraits.if_is_a] for more details.\n"
                content += "static func if_is_%s(object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:\n" % snaked_trait_name_alias
                content += indent_string + "return if_is_a(%s, object, if_callable, deferred_call)\n" % trait_full_name
                content += "\n"
                content += "## Calls the given [i]if[/i] [Callable] if and only if an object is a [%s] as trait alias [b]%s[/b], or else calls\n" % [trait_full_name, trait_name_alias]
                content += "## the given [i]else[/i] callable. The [i]if[/i] callable takes the [%s] trait as argument, and the\n" % trait_full_name
                content += "## [i]else[/i] callable does not take any argument. Returns the called callable result.\n"
                content += "## [br][br]\n"
                content += "## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and\n"
                content += "## the returned value will always be [code]null[/code].\n"
                content += "## [br][br]\n"
                content += "## See [method GTraits.if_is_a_or_else] for more details.\n"
                content += "static func if_is_%s_or_else(object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:\n" % snaked_trait_name_alias
                content += indent_string + "return if_is_a_or_else(%s, object, if_callable, else_callable, deferred_call)\n" % trait_full_name
                content += "\n"

            content += "#endregion\n"
            content += "\n"

            generated_traits.append(trait_name_alias if not trait_name_alias.is_empty() else trait_full_name)

    var output_path:String = GTraitsEditorSettings.get_instance().get_gtraits_helper_output_path()
    _gdscript_saver.save(output_path, content)
    GTraitsProjectSettings.get_instance().update_gtraits_autoload()
    _logger.debug(func(): return "   GTraits helper generated in %s" % output_path)

func _get_indent_string() -> String:
    var indent_type:GTraitsEditorSettings.IndentType = GTraitsEditorSettings.get_instance().get_editor_indent_type()
    if indent_type == GTraitsEditorSettings.IndentType.TABS:
        return "\t"
    elif indent_type == GTraitsEditorSettings.IndentType.SPACES:
        return " ".repeat(GTraitsEditorSettings.get_instance().get_editor_indent_size())
    else:
        _logger.error(func(): return "⚠️ Unknown indent type '%s'" % [GTraitsEditorSettings.IndentType.keys()[indent_type]])
        return ""

