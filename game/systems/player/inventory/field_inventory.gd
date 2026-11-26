class_name FieldInventory
extends Node
## Counts the player's fields and checks them against the limits of the current [FieldRules].
##
## All counters live here, so the rule resources stay free of state and can be shared
## between levels. Every change is reported with [signal Events.field_count_changed].
## [br]Belongs to the PlayerController, which calls it. It never calls the PlayerController.

var _rules: FieldRules
var _types: Array[FieldType] = []
## Fields placed in this level, per type.
var _placed: Dictionary[FieldType, int] = {}
## Fields that exist right now, per type.
var _active: Dictionary[FieldType, int] = {}
## The type of every field that exists right now.
var _type_of: Dictionary[GravityField, FieldType] = {}


## Starts a new level: clears all counters and reports the new counts.
func reset(rules: FieldRules, types: Array[FieldType]) -> void:
	_rules = rules
	_types = types
	_placed.clear()
	_active.clear()
	_type_of.clear()
	_report_all()


## Whether a field of [param type] may be placed right now.
func can_place(type: FieldType) -> bool:
	return remaining(type) != 0


## Fields of [param type] the strictest enabled rule still allows. -1 = unlimited.
func remaining(type: FieldType) -> int:
	var rule := _strictest_rule(type)
	return -1 if rule == null else rule.remaining(type, self)


## Fields placed in this level. [param type] null = all types together.
func placed_count(type: FieldType = null) -> int:
	return _count(_placed, type)


## Fields that exist right now. [param type] null = all types together.
func active_count(type: FieldType = null) -> int:
	return _count(_active, type)


## Counts a newly placed [param field] of [param type]. Call right after placing it.
func register(type: FieldType, field: GravityField) -> void:
	_placed[type] = _placed.get(type, 0) + 1
	_active[type] = _active.get(type, 0) + 1
	_type_of[field] = type
	# Expiring and removing both end here, so they are counted the same way.
	field.tree_exiting.connect(_on_field_exiting.bind(field), CONNECT_ONE_SHOT)
	_report_all()


## Call right before the player removes [param field] by hand.
## Gives the field back if an enabled rule says so.
func on_removed_by_player(field: GravityField) -> void:
	var type: FieldType = _type_of.get(field)
	if type == null:
		return
	for rule: FieldLimitRule in _enabled_rules():
		if rule.refunds_on_remove():
			_placed[type] = maxi(_placed.get(type, 0) - 1, 0)
			return


func _on_field_exiting(field: GravityField) -> void:
	var type: FieldType = _type_of.get(field)
	if type == null:
		return
	_type_of.erase(field)
	_active[type] = maxi(_active.get(type, 0) - 1, 0)
	_report_all()


func _report_all() -> void:
	for type: FieldType in _types:
		var rule := _strictest_rule(type)
		if rule == null:
			Events.field_count_changed.emit(type, -1, -1)
		else:
			Events.field_count_changed.emit(type, rule.remaining(type, self), rule.maximum(type))


## The enabled rule that allows the fewest fields of [param type]. null = no limits.
func _strictest_rule(type: FieldType) -> FieldLimitRule:
	var best: FieldLimitRule = null
	var best_left := -1
	for rule: FieldLimitRule in _enabled_rules():
		var left := rule.remaining(type, self)
		if left >= 0 and (best == null or left < best_left):
			best = rule
			best_left = left
	return best


func _enabled_rules() -> Array[FieldLimitRule]:
	var result: Array[FieldLimitRule] = []
	if _rules == null:
		return result
	for rule: FieldLimitRule in _rules.limit_rules:
		if rule != null and rule.enabled:
			result.append(rule)
	return result


func _count(counts: Dictionary[FieldType, int], type: FieldType) -> int:
	if type != null:
		return counts.get(type, 0)
	var total := 0
	for value: int in counts.values():
		total += value
	return total
