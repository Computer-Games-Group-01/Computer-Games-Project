class_name Lifetime
extends Timer
## Limited lifetime for the node it belongs to.
##
## A one-shot Timer that also reports how far it has run. When the time is up it emits
## [signal Timer.timeout]; the owner decides what happens then (fields free themselves).
## [br]Pause it with [member Timer.paused], end it for good with [method Timer.stop],
## restart it with another duration with [method Timer.start].
## [br]Not tied to fields: use it for anything temporary, e.g. later power-ups.
## Not meant to be restarted after it has expired.

var _expired: bool = false


func _init() -> void:
	one_shot = true
	autostart = true


func _ready() -> void:
	timeout.connect(_on_timeout)


## How far the lifetime has run: 0 = just started, 1 = expired.
## Stays 0 while stopped, e.g. when lifetimes are switched off in [FieldRules].
func progress() -> float:
	if _expired:
		return 1.0
	if is_stopped() or wait_time <= 0.0:
		return 0.0
	return 1.0 - time_left / wait_time


## Whether the lifetime has run out.
func has_expired() -> bool:
	return _expired


func _on_timeout() -> void:
	_expired = true
