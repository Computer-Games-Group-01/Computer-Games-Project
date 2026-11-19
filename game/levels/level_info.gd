class_name LevelInfo
extends Resource
## Data of one level. One .tres per level, in the level's folder.

## Name shown in menus and on the level end screen.
@export var display_name: String = ""
## The level scene, e.g. res://levels/level_01/level_01.tscn
@export_file("*.tscn") var scene_path: String = ""
## Minimum share of boids that must be rescued.
@export_range(0.1, 1.0, 0.05) var required_rescue_ratio: float = 0.5
