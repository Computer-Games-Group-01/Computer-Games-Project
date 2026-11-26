class_name ItemType
extends ItemDefinition
## An item the player collects and uses from the item bar, e.g. a power-up.
##
## Pure data, shared by every slot that holds this item. What an item does is not decided here:
## effects listen to the item signals in [Events] and check [member ItemDefinition.id].

## How many of this item fit into one slot.
@export_range(1, 99) var max_stack: int = 1
