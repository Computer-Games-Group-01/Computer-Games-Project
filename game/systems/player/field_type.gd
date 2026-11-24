class_name FieldType
extends Resource
## A field the player can place: its name, scene and id.

## Unique id, used for limits and usage statistics, e.g. &"gravity".
## Do not change it once levels or statistics rely on it.
@export var id: StringName = &""
## Name shown in the HUD.
@export var display_name: String = "Feld"
## Icon for a later item bar in the HUD (optional).
@export var icon: Texture2D
## Scene of the field. Its root must be a GravityField.
@export var scene: PackedScene
