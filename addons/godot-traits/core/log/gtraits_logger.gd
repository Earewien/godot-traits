extends RefCounted
class_name GTraitsLogger

##
## Logging utility for [i]Godot Traits[/i].
##
## [color=red]This is an internal API.[/color]

#------------------------------------------
# Constants
#------------------------------------------

## Logging level
enum GTraitsLoggerLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

#------------------------------------------
# Signals
#------------------------------------------

#------------------------------------------
# Exports
#------------------------------------------

#------------------------------------------
# Public variables
#------------------------------------------

## Current logging level, see [enum GTraitsLogger.GTraitsLoggerLevel]
var log_level: GTraitsLoggerLevel = GTraitsLoggerLevel.WARN

#------------------------------------------
# Private variables
#------------------------------------------

var _context: String

#------------------------------------------
# Godot override functions
#------------------------------------------

func _init(context: String, level: GTraitsLoggerLevel = GTraitsLoggerLevel.INFO) -> void:
    _context = context.substr(0, 20).rpad(20)
    log_level = level

#------------------------------------------
# Public functions
#------------------------------------------

func debug(callable: Callable) -> void:
    if log_level <= GTraitsLoggerLevel.DEBUG:
        print("[%s][DEBUG] %s" % [_context, callable.call()])

func info(callable: Callable) -> void:
    if log_level <= GTraitsLoggerLevel.INFO:
        print("[%s][INFO ] %s" % [_context, callable.call()])

func warn(callable: Callable) -> void:
    if log_level <= GTraitsLoggerLevel.WARN:
        print("[%s][WARN ] %s" % [_context, callable.call()])

func error(callable: Callable) -> void:
    if log_level <= GTraitsLoggerLevel.INFO:
        printerr("[%s][ERROR] %s" % [_context, callable.call()])

#------------------------------------------
# Private functions
#------------------------------------------
