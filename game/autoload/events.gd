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
signal field_type_changed(type_name: String)
signal message(text: String)
