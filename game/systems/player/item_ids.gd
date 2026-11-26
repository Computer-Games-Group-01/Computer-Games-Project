class_name ItemIds
extends RefCounted
## Ids of player actions that are not field types, used for usage statistics.
## Field types use [member FieldType.id] instead.
## Only use these constants in code, never the ids as text.

const FIELD_REMOVE := &"field_remove"
const SWARM_SPLIT := &"swarm_split"
const SWARM_MERGE := &"swarm_merge"
