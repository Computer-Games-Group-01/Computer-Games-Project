extends Node
## Global signals for events that concern several scenes.
## Emitted by systems and building blocks, received by the HUD, menus and Main.

@warning_ignore_start("unused_signal")

signal level_started(info: LevelInfo)
signal round_progress(result: RoundResult)
signal level_won(result: RoundResult)
signal level_lost(result: RoundResult)
signal boids_rescued(count: int)
signal swarm_stats_changed(swarm_count: int, boid_count: int, active_text: String)
## The player selected another field type. null = no field types are configured.
signal field_type_changed(type: FieldType)
## Fields of [param type] the player can still place. -1 = unlimited.
signal field_count_changed(type: FieldType, remaining: int, maximum: int)
## The player used an item or action. Fields and items send their [member ItemDefinition.id],
## other actions an [ItemIds] constant. Statistics use the id as key.
signal item_used(item_id: StringName)
## The abilities the player can always use, one per field type, in bar order.
signal abilities_changed(types: Array[FieldType])
## The item inventory now has [param capacity] slots. Each one is reported right after with
## [signal item_slot_changed].
signal item_capacity_changed(capacity: int)
## Item slot [param slot] now holds [param amount] items of [param type]. type null = empty.
signal item_slot_changed(slot: int, type: ItemType, amount: int)
## An item from item slot [param slot] was used. Its effect lasts while [param lifetime] runs.
## lifetime null = instant item, the effect happens once.
signal item_activated(slot: int, type: ItemType, lifetime: Lifetime)
## The effect of the item from item slot [param slot] has ended.
signal item_expired(slot: int, type: ItemType)
signal message(text: String)
