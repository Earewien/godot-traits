extends Node
class_name GTraitsFileSystem

##
## Filesystem utility for [GTraits].
##
## [color=red]This is an internal API.[/color]

## Information about a [PackedScene]
class PackedSceneInfo extends RefCounted:
    ## Path to the [PackedScene]
    var packed_scene_path:String
    ## Scene root script information, may be null if scene has no root script
    var script_info:ScriptInfo

    func _init(path:String, root_script_info:ScriptInfo) -> void:
        packed_scene_path = path
        script_info = root_script_info

    ## Returns the [PackedScene] instance
    func get_packed_scene() -> PackedScene:
        if ResourceLoader.exists(packed_scene_path, "PackedScene"):
            return ResourceLoader.load(packed_scene_path, "PackedScene")
        return null

    ## Returns [code]true[/code] if the packed scene has a root script, [code]false[/code] otherwise
    func has_script() -> bool:
        return script_info != null

## Information about a [Script]
class ScriptInfo extends RefCounted:
    ## Script file name
    var script_file_name:String
    ## Script file path
    var script_path:String
    ## Class information about all classes in this script
    var class_info:Array[GTraitsGDScriptParser.ClassInfo]

    var _top_level_class_info:GTraitsGDScriptParser.ClassInfo

    func _init(script_info:GTraitsGDScriptParser.ScriptInfo) -> void:
        script_file_name = script_info.script_file_name
        script_path = script_info.script_path
        class_info.append_array(script_info.class_info)
        for ci in class_info:
            if ci.is_top_level:
                _top_level_class_info = ci
                break

    ## Returns if this script has a top level class, defined by the [code]class_name[/code] keyword
    func has_top_level_class() -> bool:
        return _top_level_class_info != null

    ## Returns the top level class, defined by the [code]class_name[/code] keyword, or [code]null[/code]
    ## if this script does not have top level class
    func get_top_level_class() -> GTraitsGDScriptParser.ClassInfo:
        return _top_level_class_info

    ## Returns the [Script] instance
    func get_script() -> Script:
        if ResourceLoader.exists(script_path, "GDScript"):
            return ResourceLoader.load(script_path, "GDScript")
        return null

#------------------------------------------
# Constants
#------------------------------------------

#------------------------------------------
# Signals
#------------------------------------------

## Emitted when some scene files have been updated
signal on_scenes_changed(scene_info:Array[PackedSceneInfo])
## Emitted when some scene files have been deleted
signal on_scenes_removed(scene_info:Array[PackedSceneInfo])

## Emitted when some script files have been updated
signal on_scripts_changed(scene_info:Array[ScriptInfo])
## Emitted when some script files have been deleted
signal on_scripts_removed(scene_info:Array[PackedSceneInfo])

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
static var _instance:GTraitsFileSystem

# All [PackedSceneInfo] by scene path
var _scene_info_by_path:Dictionary
# All [ScriptInfo] by scene path
var _script_info_by_path:Dictionary

# Utility to parse scripts
var _gdscript_parser:GTraitsGDScriptParser = GTraitsGDScriptParser.new()
# Logger
var _logger:GTraitsLogger = GTraitsLogger.new("gtraits_fs")

#------------------------------------------
# Godot override functions
#------------------------------------------

#------------------------------------------
# Public functions
#------------------------------------------

## Returns the [GTraitsFileSystem] instance
static func get_instance() -> GTraitsFileSystem:
    if _instance == null:
        _instance = GTraitsFileSystem.new()
    return _instance

## Initialize FS when addon is starting-up
func initialize() -> GTraitsFileSystem:
    var editor_plugin:GodotTraitsEditorPlugin = GodotTraitsEditorPlugin.get_instance()
    var fs_dock:FileSystemDock = EditorInterface.get_file_system_dock()
    var editor_node:Node = EditorInterface.get_base_control().get_parent()
    if not editor_plugin.resource_saved.is_connected(_on_resource_saved):
        editor_plugin.resource_saved.connect(_on_resource_saved)
    if not fs_dock.file_removed.is_connected(_on_file_removed):
        fs_dock.file_removed.connect(_on_file_removed)
    if not fs_dock.files_moved.is_connected(_on_files_moved):
        fs_dock.files_moved.connect(_on_files_moved)
    if not editor_node.scene_saved.is_connected(_on_scene_saved):
        editor_node.scene_saved.connect(_on_scene_saved)

    _scan_fs_for_scenes_and_scripts()

    return self

## Uninitialize FS when addon is shutting down
func uninitialize() -> GTraitsFileSystem:
    var editor_plugin:GodotTraitsEditorPlugin = GodotTraitsEditorPlugin.get_instance()
    var fs_dock:FileSystemDock = EditorInterface.get_file_system_dock()
    var editor_node:Node = EditorInterface.get_base_control().get_parent()
    if editor_plugin.resource_saved.is_connected(_on_resource_saved):
        editor_plugin.resource_saved.disconnect(_on_resource_saved)
    if fs_dock.file_removed.is_connected(_on_file_removed):
        fs_dock.file_removed.disconnect(_on_file_removed)
    if fs_dock.files_moved.is_connected(_on_files_moved):
        fs_dock.files_moved.disconnect(_on_files_moved)
    if editor_node.scene_saved.is_connected(_on_scene_saved):
        editor_node.scene_saved.disconnect(_on_scene_saved)

    _instance = null

    return self

func get_scripts() -> Array[ScriptInfo]:
    var scripts:Array[ScriptInfo] = []
    scripts.append_array(_script_info_by_path.values())
    return scripts

#------------------------------------------
# Private functions
#------------------------------------------

func _on_scene_saved(scene_path:String):
     _on_packed_scene_changed(scene_path)

func _on_resource_saved(resource:Resource) -> void:
    if resource.resource_path.get_extension() == "tscn":
        _on_packed_scene_changed(resource.resource_path)
    elif resource.resource_path.get_extension() == "gd":
        _on_script_changed(resource.resource_path)

func _on_file_removed(file_path:String) -> void:
    if file_path.get_extension() == "tscn":
        _on_packed_scene_removed(file_path)
    elif file_path.get_extension() == "gd":
        _on_script_removed(file_path)

func _on_files_moved(old_file_path:String, new_file_path:String) -> void:
    if old_file_path.get_extension() == "tscn" and new_file_path.get_extension() == "tscn":
        _on_packed_scene_removed(old_file_path)
        _on_packed_scene_changed(new_file_path)
    elif old_file_path.get_extension() == "gd" and new_file_path.get_extension() == "gd":
        _on_script_removed(old_file_path)
        _on_script_changed(new_file_path)

func _on_packed_scene_changed(packed_scene_path:String) -> void:
    _logger.info(func(): return "Scene changed: '%s'" % packed_scene_path)
    var packed_scene_info:PackedSceneInfo = _register_packed_scene(packed_scene_path, true)
    if packed_scene_info != null:
        on_scenes_changed.emit([packed_scene_info])

func _on_script_changed(script_path:String) -> void:
    _logger.info(func(): return "Script changed: '%s'" % script_path)
    var script_info:ScriptInfo = _register_script_info(script_path, false)
    if script_info != null:
        on_scripts_changed.emit([script_info])

func _on_packed_scene_removed(packed_scene_path:String) -> void:
    _logger.info(func(): return "Scene removed: '%s'" % packed_scene_path)
    if _scene_info_by_path.has(packed_scene_path):
        on_scenes_removed.emit([_scene_info_by_path[packed_scene_path]])
        _scene_info_by_path.erase(packed_scene_path)

func _on_script_removed(script_path:String) -> void:
    _logger.info(func(): return "Script removed: '%s'" % script_path)
    if _script_info_by_path.has(script_path):
        on_scripts_removed.emit([_script_info_by_path[script_path]])
        _script_info_by_path.erase(script_path)

func _scan_fs_for_scenes_and_scripts() -> void:
    # Start by clearing all local data
    if not _scene_info_by_path.is_empty():
        on_scenes_removed.emit(_scene_info_by_path.values().duplicate())
        _scene_info_by_path.clear()
    if not _script_info_by_path.is_empty():
        on_scripts_removed.emit(_script_info_by_path.values().duplicate())
        _script_info_by_path.clear()

    # Scan FS for scenes and scripts. Start bu scene, since scanning scenes also scans
    #their root script: some work will not be done twice !
    var scene_paths:PackedStringArray = _recursive_find_files("res://", "tscn")
    var script_paths:PackedStringArray = _recursive_find_files("res://", "gd")

    for scene_path in scene_paths:
        _register_packed_scene(scene_path, false)
        var scene_info:PackedSceneInfo = _build_packed_scene_info(scene_path)

    for script_path in script_paths:
        # Scenes may have already brings some script info, do not repase them in the same pass
        if not _script_info_by_path.has(script_path):
            _register_script_info(script_path, false)
            var script_info:ScriptInfo = _build_script_info(script_path)
            if script_info != null:
                _script_info_by_path[script_path] = script_info
            else:
                _logger.warn(func(): return "⚠️ Script file '%s' can not be loaded, ignoring it" % script_path)

    # Finally, emit the changes
    _logger.info(func(): return "FS full scan: %s scene(s) and %s script(s) found" % [_scene_info_by_path.size(), _script_info_by_path.size()])
    if not _scene_info_by_path.is_empty():
        on_scenes_changed.emit(_scene_info_by_path.values().duplicate())
    if not _script_info_by_path.is_empty():
        on_scenes_changed.emit(_script_info_by_path.values().duplicate())

func _register_packed_scene(packed_scene_path:String, use_cache:bool = false) -> PackedSceneInfo:
    var scene_info:PackedSceneInfo = _build_packed_scene_info(packed_scene_path, use_cache)
    if scene_info != null:
        _scene_info_by_path[packed_scene_path] = scene_info
        if scene_info.has_script():
            var script_info:ScriptInfo = _build_script_info(scene_info.script_info.script_path, use_cache)
            if script_info != null:
                _script_info_by_path[scene_info.script_info.script_path] = script_info
            else:
                _logger.warn(func(): return "⚠️ Script file '%s' can not be loaded, ignoring it" % scene_info.script_info.script_path)
    else:
        _logger.warn(func(): return "⚠️ Scene file '%s' can not be loaded, ignoring it" % packed_scene_path)

    return scene_info

func _build_packed_scene_info(scene_path:String, use_script_info_cache:bool = false) -> PackedSceneInfo:
    if not ResourceLoader.exists(scene_path, "PackedScene"):
        return null

    var packed_scene:PackedScene = ResourceLoader.load(scene_path, "PackedScene")
    # Find the root script, if it exists
    var packed_scene_state:SceneState = packed_scene.get_state()
    var root_script_path:String = ""
    for node_number in packed_scene_state.get_node_count():
        if packed_scene_state.get_node_path(node_number) == ^".":
            for prop_number in packed_scene_state.get_node_property_count(node_number):
                if packed_scene_state.get_node_property_name(node_number, prop_number) == "script":
                    root_script_path = packed_scene_state.get_node_property_value(node_number, prop_number).resource_path
                    break
            # Stop here since root node has been parsed
            break

    var root_script_info:ScriptInfo = _build_script_info(root_script_path, use_script_info_cache) if not root_script_path.is_empty() else null
    _logger.debug(func(): return "Scene file '%s' has been parsed (root script: %s)" % [scene_path, root_script_info != null])
    return PackedSceneInfo.new(scene_path, root_script_info)

func _register_script_info(script_path:String, use_cache:bool = false) -> ScriptInfo:
    var script_info:ScriptInfo = _build_script_info(script_path, use_cache)
    if script_info != null:
        _script_info_by_path[script_path] = script_info
    else:
        _logger.warn(func(): return "⚠️ Script file '%s' can not be loaded, ignoring it" % script_path)
    return script_info

func _build_script_info(script_path:String, use_script_info_cache:bool = false) -> ScriptInfo:
    if use_script_info_cache and _script_info_by_path.has(script_path):
        return _script_info_by_path[script_path]

    var parse_script_info:GTraitsGDScriptParser.ScriptInfo = _gdscript_parser.get_script_info_from_file(script_path)
    if parse_script_info != null:
        _logger.debug(func(): return "Script file '%s' has been parsed" % script_path)
        return ScriptInfo.new(parse_script_info)
    return null

func _recursive_find_files(path:String = "res://", ext:String = "") -> PackedStringArray:
    # Since resource path is a key to identify resource, make sur each path is canonical !
    path = path.simplify_path()
    var file_paths:PackedStringArray = []

    # Recursive search in directory
    if DirAccess.dir_exists_absolute(path):
        var res_dir:DirAccess = DirAccess.open(path)
        res_dir.list_dir_begin()
        var file_name = res_dir.get_next()
        while file_name != "":
            file_paths.append_array(_recursive_find_files(path.path_join(file_name), ext))
            file_name = res_dir.get_next()
    # Path represents a file !
    elif FileAccess.file_exists(path):
        if ext.is_empty() or path.get_extension() == ext:
            file_paths.append(path)

    return file_paths
