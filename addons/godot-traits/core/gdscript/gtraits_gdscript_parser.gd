extends RefCounted
class_name GTraitsGDScriptParser

##
## GDScript light parser for [i]Godot Traits[/i].
##
## [color=red]This is an internal API.[/color]

## Class annotations
class ClassAnnotation:
    ## Annotation name
    var name:String
    ## Annotation options, as keys and values
    var options:Dictionary

    func _init(n:String, opts:Dictionary = {}):
        name = n
        options = opts

    func _to_string() -> String:
        return "ClassAnnotation[%s, %s options]" % [name, options.size()]

## Class informations
class ClassInfo:
    ## Class name, as declared in script file by [code]class_name[/code] or [code]class[/code] keywords
    var declared_class_name:String
    ## Qualified class name, [i]i.e.[/i] the named used to reference this class outside the file
    ## (with parent class names)
    var qualified_class_name: String
    ## Path to the script declaring this class
    var script_path:String
    ## Class annotations, keys are annotation name, value is a [ClassAnnotation]
    var annotations:Dictionary
    ## Is this class the top level class, as declared by the [code]class_name[/code] keyword
    var is_top_level:bool

    func _init(name:String, top_level:bool = false, full_name:String = "", sp:String = "", annots:Array[ClassAnnotation] = []):
        declared_class_name = name
        qualified_class_name = full_name if full_name else name
        script_path = sp
        for annotation in annots:
            annotations[annotation.name] = annotation
        is_top_level = top_level

    func _to_string() -> String:
        return "ClassInfo[%s, %s, %s, %s annotations]" % [declared_class_name, qualified_class_name, ("Top Level" if is_top_level else "Inner"), annotations.size()]

## Get script informations, like base information like path, and script content
class ScriptInfo:
    ## Script file name
    var script_file_name:String
    ## Script file path
    var script_path:String
    ## Class information about all classes in this script
    var class_info:Array[ClassInfo] = []:
        set(value):
            class_info = value
            for ci in class_info:
                if ci.is_top_level:
                    _top_level_class_info = ci
                    break

    var _top_level_class_info:ClassInfo

    ## Returns if this script has a top level class, defined by the [code]class_name[/code] keyword
    func has_top_level_class() -> bool:
        return _top_level_class_info != null

    ## Returns the top level class, defined by the [code]class_name[/code] keyword, or [code]null[/code]
    ## if this script does not have top level class
    func get_top_level_class() -> ClassInfo:
        return _top_level_class_info

    func _to_string() -> String:
        return "ScriptInfo[%s, %s, %s]" % [script_file_name, script_path, class_info]

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

#------------------------------------------
# Godot override functions
#------------------------------------------

## Returns complete script information
## See [ScriptInfo] for accessible information.
func get_script_info(script:Script) -> ScriptInfo:
    return get_script_info_from_file(script.resource_path)

## Returns complete script information
## See [ScriptInfo] for accessible information.
func get_script_info_from_file(script_path:String) -> ScriptInfo:
    var script_info:ScriptInfo = ScriptInfo.new()
    script_info.script_file_name = script_path.get_file()
    script_info.script_path = script_path

    if FileAccess.file_exists(script_path):
        var lines:PackedStringArray = FileAccess.get_file_as_string(script_path).split("\n")
        script_info.class_info = _parse_class_info(lines, script_path)

    return script_info

#------------------------------------------
# Public functions
#------------------------------------------

#------------------------------------------
# Private functions
#------------------------------------------

func _get_indent_level(line:String) -> int:
    return line.length() - line.strip_edges(true, false).length()

func _is_annotation_declaration(line:String) -> bool:
    if line.is_empty() or not line[0] == "#":
        return false

    var possible_annotation_line:String = line.substr(1).lstrip(" \t")
    return not possible_annotation_line.is_empty() and possible_annotation_line[0] == "@"

func _is_top_level_class_declaration(line:String) -> bool:
    return line.begins_with("class_name ")

func _is_inner_class_declaration(line:String) -> bool:
    return line.begins_with("class ")

func _is_comment(line:String) -> bool:
    return not line.is_empty() and line[0] == "#"

func _parse_class_info(lines:PackedStringArray, script_path:String) -> Array[ClassInfo]:
    # The top level class, as declared by the class_name keyword. May be empty is not found
    var main_class_name: String = ""
    # Stack class info like objects into a stack, help to determine class parenting
    var class_stack:Array[Dictionary] = []
    # Will store encountered annotations until a class is found
    var annotations_queue:Array[ClassAnnotation] = []
    # The resulting class information
    var class_infos:Array[ClassInfo] = []

    for line in lines:
        # Indent level helps determine class parenting
        var line_indent = _get_indent_level(line)
        # Use trimed line content for parsing, since indent level has already been computed abvove
        var trimed_line_content = line.strip_edges()

        # Handle annotations
        if _is_annotation_declaration(trimed_line_content):
            annotations_queue.append(_parse_annotation(trimed_line_content))
        # Handle top level class declaration
        elif _is_top_level_class_declaration(trimed_line_content):
            main_class_name = trimed_line_content.split(" ")[1]
            class_infos.append(ClassInfo.new(main_class_name, true, main_class_name, script_path, annotations_queue))
            class_stack.append({
                "name": main_class_name,
                "full_name": main_class_name,
                "indent": -1 # indicated root level
            })
            # Reset annotations for next classes
            annotations_queue.clear()
        # Handle inner class declaration
        elif _is_inner_class_declaration(trimed_line_content):
            # Compute class parenting based on line indent
            while class_stack and class_stack[-1]["indent"] >= line_indent:
                class_stack.pop_back()

            # Compute class info
            var the_class_name = trimed_line_content.split(" ")[1].split(":")[0]
            var parent_full_name = class_stack[-1]["full_name"] if class_stack.size() > 0 else ""
            var full_class_name = (parent_full_name + "." if parent_full_name else "") + the_class_name

            class_infos.append(ClassInfo.new(the_class_name, main_class_name == full_class_name, full_class_name, script_path, annotations_queue))
            class_stack.append({
                "name": the_class_name,
                "full_name": full_class_name,
                "indent": line_indent
            })

            # Reset annotations for next classes
            annotations_queue.clear()
        elif _is_comment(trimed_line_content):
            # When encountering a comment, we keep the enqueud annotations until we found a class
            pass
        else:
            # Nothing we care about, so we have to clear the annotation queue since found annotations
            # do not belongs to classes
            annotations_queue.clear()

    return class_infos

func _parse_annotation(line:String) -> ClassAnnotation:
    var annotation_name:String = ""
    var annotation_options:Dictionary = {}

    # Strip line from annotation prefix
    var index_of_annotation_start_char:int = line.find("@")
    assert(index_of_annotation_start_char != -1, "Line does not contain an annotation")
    #line = line.substr(index_of_annotation_start_char + 1, line.length() - index_of_annotation_start_char - 1)
    line = line.lstrip("#@ \t")

    # Then check if there are parameters
    var index_of_opening_parenthesis:int = line.find("(")
    var index_of_closing_parenthesis:int = line.find(")")
    # If there are parameters, parse them. If we can not find the clsing parenthesis, not a big deal...
    if index_of_opening_parenthesis != -1:
        var options_content:String = line.substr(index_of_opening_parenthesis + 1, index_of_closing_parenthesis - index_of_opening_parenthesis - 1 if index_of_closing_parenthesis != -1 else -1)
        var splitted_options:PackedStringArray = options_content.split(",")
        for splitted_option in splitted_options:
            var splitted_key_value:PackedStringArray = splitted_option.strip_edges().split("=")
            annotation_options[splitted_key_value[0].strip_edges()] = splitted_key_value[1].strip_edges()

    # Determine annotation name
    annotation_name = line.substr(0, index_of_opening_parenthesis)

    return ClassAnnotation.new(annotation_name, annotation_options)
