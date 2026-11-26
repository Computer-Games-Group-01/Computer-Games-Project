class_name InputActions
extends RefCounted
## names of all actions in the input map
## only use these constants in the code, never the names as text

const CAMERA_PAN_UP := &"camera_pan_up"
const CAMERA_PAN_LEFT := &"camera_pan_left"
const CAMERA_PAN_DOWN := &"camera_pan_down"
const CAMERA_PAN_RIGHT := &"camera_pan_right"
const CAMERA_ZOOM_IN := &"camera_zoom_in"
const CAMERA_ZOOM_OUT := &"camera_zoom_out"
const FIELD_PLACE := &"field_place"
const FIELD_REMOVE := &"field_remove"
const FIELD_GROW := &"field_grow"
const FIELD_SHRINK := &"field_shrink"
const FIELD_TYPE_NEXT := &"field_type_next"
const SWARM_SPLIT := &"swarm_split"
const SWARM_MERGE := &"swarm_merge"
const SWARM_NEXT := &"swarm_next"
const DEBUG_OVERLAY := &"debug_overlay"
const ROUND_RESTART := &"round_restart"
const ROUND_FINISH := &"round_finish"
const ABILITY_NEXT := &"ability_next"
const ABILITY_PREVIOUS := &"ability_previous"
const DEBUG_GIVE_ITEMS := &"debug_give_items"


## Action that selects ability slot [param index] (0 = first slot): &"ability_1", &"ability_2", …
## More slots only need more actions with this name in Project Settings > Input Map.
static func ability_slot(index: int) -> StringName:
	return StringName("ability_%d" % (index + 1))


## Action that uses item slot [param index] (0 = first slot): &"item_1", &"item_2", …
## More slots only need more actions with this name in Project Settings > Input Map.
static func item_slot(index: int) -> StringName:
	return StringName("item_%d" % (index + 1))


## Name of the first key bound to [param action], in the player's keyboard layout, e.g. "X".
## Empty if the action does not exist or has no key. Used for the key hints in the HUD.
static func key_label(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event: InputEvent in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key == null:
			continue
		if key.physical_keycode != KEY_NONE:
			return OS.get_keycode_string(
					DisplayServer.keyboard_get_keycode_from_physical(key.physical_keycode))
		return OS.get_keycode_string(key.keycode)
	return ""
