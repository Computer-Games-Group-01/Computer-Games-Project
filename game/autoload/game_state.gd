extends Node
## Game state across level changes: which level is running.

const LEVEL_LIST: LevelList = preload("res://levels/level_list.tres")

var current_index: int = 0
## Set when a level was started directly with F6.
var start_info: LevelInfo = null


## Starts over and returns the first level.
func start_new_game() -> LevelInfo:
	current_index = 0
	start_info = null
	return current()


## Remembers a level that was started directly (F6).
func start_at(info: LevelInfo) -> void:
	start_info = info
	current_index = maxi(LEVEL_LIST.levels.find(info), 0)


## The current level, null = none left.
func current() -> LevelInfo:
	if start_info != null:
		return start_info
	if current_index < LEVEL_LIST.levels.size():
		return LEVEL_LIST.levels[current_index]
	return null


## Moves on to the next level. null = there is none.
func advance() -> LevelInfo:
	start_info = null
	current_index += 1
	return current()
