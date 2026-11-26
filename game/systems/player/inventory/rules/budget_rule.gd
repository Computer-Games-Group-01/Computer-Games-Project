class_name BudgetRule
extends FieldLimitRule
## Budget per level: every placed field uses up one. Expired fields do not come back.

## Fields per level (per field type if [member per_type] is on).
@export_range(0, 999) var amount: int = 10
## On = every field type has its own budget. Off = one budget shared by all types.
@export var per_type: bool = true
## Different budgets for single field types (only with [member per_type]).
## Types missing here use [member amount].
@export var amount_per_type: Dictionary[FieldType, int] = {}
## On = a field the player removes by hand is given back.
@export var refund_on_remove: bool = false


func remaining(type: FieldType, inventory: FieldInventory) -> int:
	var counted: FieldType = type if per_type else null
	return maxi(maximum(type) - inventory.placed_count(counted), 0)


func maximum(type: FieldType) -> int:
	if per_type and amount_per_type.has(type):
		return amount_per_type[type]
	return amount


func refunds_on_remove() -> bool:
	return refund_on_remove
