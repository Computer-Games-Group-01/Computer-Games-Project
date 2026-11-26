extends Node
## Entry point of the game: loads the current level and connects HUD and World.

@onready var world: World = %World
@onready var hud: Hud = %Hud


func _ready() -> void:
	hud.split_requested.connect(world.player_controller.split_active_swarm)
	hud.merge_requested.connect(world.player_controller.merge_nearby_swarms)
	hud.next_swarm_requested.connect(world.player_controller.select_next_swarm)
	hud.ability_pressed.connect(world.player_controller.select_ability)
	_load_level(GameState.current())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.ROUND_RESTART):
		_load_level(GameState.current())


func _load_level(info: LevelInfo) -> void:
	world.unload_level()
	var scene := load(info.scene_path) as PackedScene
	world.load_level(scene.instantiate() as LevelRoot)
