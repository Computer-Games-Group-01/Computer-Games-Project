class_name RoundResult
extends RefCounted
## Record of one round. RoundRules fills it, the HUD and statistics read it.
##
## Nothing changes after [signal Events.level_won] or [signal Events.level_lost], so a
## statistic may keep the object as the final result of this attempt.

## The level of this round.
var level_info: LevelInfo
var total: int = 0
var rescued: int = 0
var required: int = 0
var remaining: int = 0
var finished: bool = false
var success: bool = false
## Seconds played, without pauses. Stops when the round ends.
var duration: float = 0.0
## How often each item or action was used successfully, by id
## ([member ItemDefinition.id] or an [ItemIds] constant).
var item_usage: Dictionary[StringName, int] = {}


## Uses of [param item_id] in this round. 0 = never used.
func uses_of(item_id: StringName) -> int:
	return item_usage.get(item_id, 0)


## One line for the output, e.g. for playtests.
func _to_string() -> String:
	var level_name := level_info.display_name if level_info != null else "?"
	return "%s: %s, %d / %d rescued (goal %d), %.1f s, usage %s" % [level_name,
			"won" if success else "lost", rescued, total, required, duration, item_usage]
