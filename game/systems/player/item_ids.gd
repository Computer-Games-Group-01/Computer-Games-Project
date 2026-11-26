class_name ItemIds
extends RefCounted
## Ids of player actions that are neither field types nor items, used for usage statistics.
## Field types and items use [member ItemDefinition.id] instead.
## Only use these constants in code, never the ids as text.

const FIELD_REMOVE := &"field_remove"
const SWARM_SPLIT := &"swarm_split"
const SWARM_MERGE := &"swarm_merge"
