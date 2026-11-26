class_name PlayerController
extends Node2D
## All player input in the game world:
##   Left click            place a field (default size)
##   Left click + drag     place a field, size = distance to the click point
##   Right click           remove the field under the mouse cursor
##   Q / E                 shrink/grow the field under the cursor (otherwise the last one placed)
##   F                     next ability (field type)
##   Shift + mouse wheel   next/previous ability
##   1, 2, … or a click    select that ability (Input Map: ability_1, ability_2, …)
##   X, C, V or a click    use that item (Input Map: item_1, item_2, …)
##   Space, M, Tab         split swarm, merge nearby swarms, select next swarm
##   F3                    BoidWorld debug overlay
##   F4                    add the debug items (debug builds only)
##
## Abilities are the field types and always available. Items are collected and sit in the
## [ItemInventory]. All keys are actions in Project Settings > Input Map.
##
## Features such as lifetime, limits and statistics plug in through the hook methods at the
## end of this script. Each feature only changes those hooks, so features can be built in parallel.

## The simulation. Placed fields are registered here.
@export var boid_world: BoidWorld
## Moves to the new swarm when the swarm changes.
@export var camera: CameraRig
## Placed fields are added here.
@export var fields_root: Node2D
## Rules for placed fields when the level has none of its own ([member LevelInfo.field_rules]).
@export var default_rules: FieldRules

@export_group("Fields")
## Field types, shown as abilities in this order. F cycles through them.
@export var field_types: Array[FieldType] = []
@export var default_radius: float = 280.0
@export var drag_threshold: float = 14.0
## Share per second while Q or E is held.
@export var resize_rate: float = 1.2

@export_group("Swarm split")
## Field that pulls the halves apart.
@export var tear_scene: PackedScene
@export var tear_distance: float = 520.0

@export_group("Swarm merge")
@export var merge_distance: float = 700.0

@export_group("Debug")
## Items F4 adds to the inventory, to test the item bar without pickups. Debug builds only.
@export var debug_items: Array[ItemType] = []

## Field rules of the current level.
var _rules: FieldRules
var _type_index: int = 0
var _dragging: GravityField = null
var _drag_origin: Vector2 = Vector2.ZERO
var _last_field: GravityField = null

@onready var _inventory: FieldInventory = %FieldInventory
@onready var _items: ItemInventory = %ItemInventory


func _ready() -> void:
	_rules = _rules_or_default(null)
	boid_world.swarm_fragmented.connect(_on_swarm_fragmented)
	for type: FieldType in field_types:
		if type.id.is_empty():
			push_warning("FieldType '%s' has no id. Set it in its .tres file." % type.display_name)


## Resets the input for a new level. World calls this when a level is loaded.
## [param rules] are the level's field rules; null = [member default_rules].
func reset(rules: FieldRules = null) -> void:
	_rules = _rules_or_default(rules)
	_dragging = null
	_last_field = null
	Events.abilities_changed.emit(field_types)
	_select_type(0)
	_on_reset()


## The selected field type. null = no field types are configured.
func current_type() -> FieldType:
	if _type_index < field_types.size():
		return field_types[_type_index]
	return null


## Name of the selected field type.
func current_type_name() -> String:
	var type := current_type()
	return type.display_name if type != null else "Feld"


## Makes ability [param index] (0 = first field type) the one placed next.
## Out of range = no change.
func select_ability(index: int) -> void:
	if index >= 0 and index < field_types.size():
		_select_type(index)
		
## Uses one item from item slot [param index] (see [method ItemInventory.use]).
func use_item(index: int) -> void:
	_items.use(index)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(InputActions.FIELD_PLACE):
		_begin_place()
	elif event.is_action_released(InputActions.FIELD_PLACE):
		_end_place()
	elif event is InputEventMouseMotion and is_instance_valid(_dragging):
		var d := get_global_mouse_position().distance_to(_drag_origin)
		if d > drag_threshold:
			_dragging.radius = d
	elif event.is_action_pressed(InputActions.FIELD_REMOVE):
		var f := _field_under_cursor()
		if f != null and f.removable:
			_remove_field(f)
	elif event.is_action_pressed(InputActions.FIELD_TYPE_NEXT):
		_step_ability(1)
	elif event.is_action_pressed(InputActions.ABILITY_NEXT):
		_step_ability(1)
	elif event.is_action_pressed(InputActions.ABILITY_PREVIOUS):
		_step_ability(-1)
	elif event.is_action_pressed(InputActions.SWARM_SPLIT):
		split_active_swarm()
	elif event.is_action_pressed(InputActions.SWARM_MERGE):
		merge_nearby_swarms()
	elif event.is_action_pressed(InputActions.SWARM_NEXT):
		select_next_swarm()
	elif event.is_action_pressed(InputActions.DEBUG_OVERLAY):
		boid_world.debug_draw = not boid_world.debug_draw
	elif event.is_action_pressed(InputActions.DEBUG_GIVE_ITEMS) and OS.is_debug_build():
		_give_debug_items()
	elif event.is_pressed() and not event.is_echo():
		var ability := _pressed_slot(event, field_types.size(), false)
		var item := _pressed_slot(event, _items.capacity, true)
		if ability >= 0:
			select_ability(ability)
		elif item >= 0:
			use_item(item)


func _process(delta: float) -> void:
	var axis := Input.get_axis(InputActions.FIELD_SHRINK, InputActions.FIELD_GROW)
	if axis == 0.0:
		return
	var f := _field_under_cursor()
	if f == null and is_instance_valid(_last_field):
		f = _last_field
	if f != null:
		f.radius *= 1.0 + axis * resize_rate * delta


## Selects the next swarm and moves the camera there.
func select_next_swarm() -> void:
	boid_world.select_next_swarm()
	if boid_world.active_swarm != null:
		camera.focus_on(boid_world.active_swarm.centroid())


## Splits the active swarm into two halves. Two short-lived fields
## on opposite sides pull the halves apart.
func split_active_swarm() -> void:
	var swarm := boid_world.active_swarm
	if swarm == null or swarm.size() < 4:
		Events.message.emit("Schwarm ist zu klein zum Teilen")
		return
	var center := swarm.centroid()
	var spread := swarm.radius()
	var heading := swarm.average_velocity()
	# Cut across the direction of travel, so the halves fly apart sideways.
	var axis := heading.orthogonal().normalized() if heading.length() > 5.0 \
			else Vector2.from_angle(randf() * TAU)
	var halves := boid_world.split_swarm(swarm, axis)
	if halves.size() < 2:
		return
	Events.item_used.emit(ItemIds.SWARM_SPLIT)
	_spawn_tear_field(halves[0], center + axis * tear_distance, spread)
	_spawn_tear_field(halves[1], center - axis * tear_distance, spread)
	Events.message.emit("Schwarm #%d geteilt" % swarm.id)


func merge_nearby_swarms() -> void:
	var count := boid_world.merge_nearby(merge_distance)
	if count > 0:
		Events.message.emit("%d Schwarm/Schwärme vereint" % count)
		Events.item_used.emit(ItemIds.SWARM_MERGE)
	else:
		Events.message.emit("Kein Schwarm in Reichweite zum Vereinen")


func _on_swarm_fragmented(original: Swarm, new_swarms: Array[Swarm]) -> void:
	Events.message.emit("Schwarm #%d zerfallen in %d Teile" % [original.id, new_swarms.size() + 1])


func _spawn_tear_field(target: Swarm, pos: Vector2, spread: float) -> void:
	var field := tear_scene.instantiate() as GravityField
	fields_root.add_child(field)
	field.global_position = pos
	field.radius = tear_distance + spread + 250.0
	field.color = target.color
	field.target_swarm = target  # affects only its own half
	field.setup(boid_world)


func _begin_place() -> void:
	var type := current_type()
	if type == null or fields_root == null or not _can_place(type):
		return
	var field := _spawn_field(type)
	_drag_origin = field.global_position
	_dragging = field
	_last_field = field
	_on_field_placed(type, field)


## Creates a field of [param type] at the mouse cursor and registers it with the simulation.
func _spawn_field(type: FieldType) -> GravityField:
	var field := type.scene.instantiate() as GravityField
	fields_root.add_child(field)
	field.global_position = get_global_mouse_position()
	field.radius = default_radius
	field.setup(boid_world)
	return field


func _end_place() -> void:
	if is_instance_valid(_dragging):
		_on_field_released(_dragging)
	_dragging = null


func _remove_field(field: GravityField) -> void:
	_on_field_removed(field)
	field.queue_free()


func _select_type(index: int) -> void:
	_type_index = index
	Events.field_type_changed.emit(current_type())


func _step_ability(step: int) -> void:
	if not field_types.is_empty():
		_select_type(posmod(_type_index + step, field_types.size()))


## Slot whose key [param event] presses, among the first [param count] slots. -1 = none.
## [param item_slots] on = check the item keys, off = the ability keys.
## Slots without an action in the Input Map are skipped, they can still be clicked.
func _pressed_slot(event: InputEvent, count: int, item_slots: bool) -> int:
	for i in count:
		var action := InputActions.item_slot(i) if item_slots else InputActions.ability_slot(i)
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return i
	return -1


func _give_debug_items() -> void:
	for type: ItemType in debug_items:
		if type != null and _items.add(type) > 0:
			Events.message.emit("Kein Platz mehr für %s" % type.display_name)


func _rules_or_default(rules: FieldRules) -> FieldRules:
	if rules != null:
		return rules
	if default_rules != null:
		return default_rules
	return FieldRules.new()


## The field whose area contains the mouse cursor (if several: the one with the nearest centre).
func _field_under_cursor() -> GravityField:
	if fields_root == null:
		return null
	var mouse := get_global_mouse_position()
	var best: GravityField = null
	var best_d := INF
	for child in fields_root.get_children():
		var f := child as GravityField
		if f != null and f.contains_point(mouse):
			var d := f.global_position.distance_to(mouse)
			if d < best_d:
				best_d = d
				best = f
	return best


# --- Feature hooks -------------------------------------------------------------
# Features change only the methods below.


## Called at the end of [method reset], after the first field type was selected.
func _on_reset() -> void:
	_inventory.reset(_rules, field_types)
	_items.reset()


## Whether a field of [param type] may be placed now.
func _can_place(type: FieldType) -> bool:
	if _inventory.can_place(type):
		return true
	Events.message.emit("Keine Felder vom Typ %s mehr übrig" % type.display_name)
	return false


## Called right after a field was placed. The mouse button may still be held for dragging.
func _on_field_placed(type: FieldType, field: GravityField) -> void:
	_apply_lifetime_rules(field)
	_inventory.register(type, field)
	Events.item_used.emit(type.id)


## Called when the mouse button is released after placing [param field].
func _on_field_released(field: GravityField) -> void:
	if field.lifetime != null:
		field.lifetime.paused = false


## Applies the lifetime settings of the current [FieldRules] to a newly placed field.
func _apply_lifetime_rules(field: GravityField) -> void:
	if field.lifetime == null:
		return
	if not _rules.lifetime_enabled:
		field.lifetime.stop()
		return
	if _rules.lifetime_override > 0.0:
		field.lifetime.start(_rules.lifetime_override)
	field.lifetime.paused = _rules.lifetime_starts_on_release


## Called right before the player removes [param field] with a right click.
func _on_field_removed(field: GravityField) -> void:
	_inventory.on_removed_by_player(field)
	Events.item_used.emit(ItemIds.FIELD_REMOVE)
