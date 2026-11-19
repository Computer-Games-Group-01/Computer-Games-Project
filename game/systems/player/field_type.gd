class_name FieldType
extends Resource
## A field the player can place.

## Name shown in the HUD.
@export var display_name: String = "Feld"
## Scene of the field; its root must be a GravityField.
@export var scene: PackedScene
