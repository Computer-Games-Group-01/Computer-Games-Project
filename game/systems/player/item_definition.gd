class_name ItemDefinition
extends Resource
## Base class for everything shown in a bar slot: field types (abilities) and items.
##
## Holds only what the HUD and the usage statistics need, so both treat fields and items alike.

## Unique id, used for limits and usage statistics, e.g. &"gravity".
## Must differ from every other id, including the [ItemIds] constants.
## Do not change it once levels or statistics rely on it.
@export var id: StringName = &""
## Name shown in the HUD, e.g. as the tooltip of a slot.
@export var display_name: String = ""
## Icon in the bar slot. Until there is pixel art, a GradientTexture2D works as a placeholder.
@export var icon: Texture2D
