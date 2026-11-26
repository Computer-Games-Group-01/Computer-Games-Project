class_name FieldRules
extends Resource
## Rules for the fields the player places: lifetime and limits.
##
## Pure settings. Systems read them but never change them at runtime, because a resource
## loaded from a .tres file is shared by everyone who uses it.
## [br]Default: [member PlayerController.default_rules]. Per level: [member LevelInfo.field_rules].

@export_group("Lifetime")
## Off = placed fields stay until the player removes them.
@export var lifetime_enabled: bool = true
## Greater than 0 = overrides the lifetime set in each field scene (quick tuning for all types).
@export_range(0.0, 60.0, 0.1, "or_greater", "suffix:s") var lifetime_override: float = 0.0
## On = a field's lifetime only starts when the mouse button is released after placing it.
@export var lifetime_starts_on_release: bool = true
@export_group("Limits")
## Limits for placing fields. A field can only be placed if every enabled rule allows it.
## Empty = unlimited.
@export var limit_rules: Array[FieldLimitRule] = []
