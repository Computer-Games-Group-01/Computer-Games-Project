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
## The player used an item or action. Fields send [member FieldType.id],
## everything else an [ItemIds] constant.
signal item_used(item_id: StringName)
signal message(text: String)
