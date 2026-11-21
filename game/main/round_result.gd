class_name RoundResult
extends RefCounted
## State of a round. RoundRules fills it, the HUD and the level end screen read it.

var total: int = 0
var rescued: int = 0
var required: int = 0
var remaining: int = 0
var finished: bool = false
var success: bool = false
