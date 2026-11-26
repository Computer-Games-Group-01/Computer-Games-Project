class_name DecayVisual
extends Node
## Shows that a [Lifetime] is running out: fades the target and makes it pulse near the end.
##
## Only changes [member CanvasItem.modulate] of the target, so it works for any CanvasItem
## without touching its _draw(). Remove the node to switch the effect off for a scene.

## The lifetime to follow.
@export var lifetime: Lifetime
## What to fade. Empty = the parent node.
@export var target: CanvasItem

@export_group("Fade")
## Opacity right before expiry. Used when [member alpha_over_life] is empty.
@export_range(0.0, 1.0, 0.01) var end_alpha: float = 0.3
## Opacity over the lifetime: x = progress (0 to 1), y = opacity. Overrides [member end_alpha].
## Keep the curve's default domain of 0 to 1.
@export var alpha_over_life: Curve

@export_group("Pulse")
## Off = no pulsing, only fading.
@export var pulse_enabled: bool = true
## Pulsing starts this many seconds before expiry.
@export_range(0.0, 30.0, 0.1, "or_greater", "suffix:s") var pulse_time_left: float = 2.0
## Pulses per second when pulsing starts.
@export_range(0.1, 20.0, 0.1, "suffix:Hz") var pulse_rate_start: float = 2.0
## Pulses per second right before expiry.
@export_range(0.1, 20.0, 0.1, "suffix:Hz") var pulse_rate_end: float = 6.0
## Opacity a pulse takes away at its lowest point (0 = none, 1 = fully transparent).
@export_range(0.0, 1.0, 0.01) var pulse_depth: float = 0.35

var _phase: float = 0.0


func _ready() -> void:
	if target == null:
		target = get_parent() as CanvasItem
	if lifetime == null:
		push_warning("DecayVisual at %s has no Lifetime assigned." % get_path())


func _process(delta: float) -> void:
	if lifetime == null or target == null:
		return
	if lifetime.is_stopped() and not lifetime.has_expired():
		target.modulate.a = 1.0
		return
	target.modulate.a = _fade_alpha() * _pulse_alpha(delta)


func _fade_alpha() -> float:
	var progress := lifetime.progress()
	if alpha_over_life != null:
		return clampf(alpha_over_life.sample(progress), 0.0, 1.0)
	return lerpf(1.0, end_alpha, progress)


func _pulse_alpha(delta: float) -> float:
	var left := lifetime.time_left
	if not pulse_enabled or pulse_time_left <= 0.0 or left > pulse_time_left \
			or lifetime.has_expired():
		_phase = 0.0
		return 1.0
	if not lifetime.paused:
		var t := 1.0 - left / pulse_time_left
		_phase += lerpf(pulse_rate_start, pulse_rate_end, t) * TAU * delta
	# Starts at full opacity and dips smoothly by pulse_depth.
	return 1.0 - pulse_depth * (0.5 - 0.5 * cos(_phase))
