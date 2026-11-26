class_name ActiveLimitRule
extends FieldLimitRule
## Limits how many fields exist at the same time.
##
## Expired or removed fields free their slot again, so together with a lifetime
## this works like a cooldown.

## Fields that may exist at the same time.
@export_range(1, 99) var max_active: int = 3
## On = the limit applies to every field type separately. Off = to all types together.
@export var per_type: bool = false


func remaining(type: FieldType, inventory: FieldInventory) -> int:
	var counted: FieldType = type if per_type else null
	return maxi(max_active - inventory.active_count(counted), 0)


func maximum(_type: FieldType) -> int:
	return max_active
