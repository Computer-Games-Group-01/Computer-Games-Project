class_name FieldLimitRule
extends Resource
## Base class for one limit on placing fields, e.g. a budget per level.
##
## A rule only holds settings and reads the counters of a [FieldInventory], so one .tres can be
## shared by several levels. New kinds of limits (e.g. a cooldown) extend this class and
## override [method remaining] and [method maximum]; [FieldInventory] does not change.

## Off = the rule is ignored.
@export var enabled: bool = true


## How many more fields of [param _type] this rule allows right now. -1 = unlimited.
func remaining(_type: FieldType, _inventory: FieldInventory) -> int:
	return -1


## The total this rule allows for [param _type], shown in the HUD. -1 = unlimited.
func maximum(_type: FieldType) -> int:
	return -1


## Whether a field the player removes by hand is given back.
func refunds_on_remove() -> bool:
	return false
