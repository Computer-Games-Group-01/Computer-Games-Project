extends PointLight2D
## Makes the anglerfish lure light pulse slowly.
## The base brightness is the light's own Energy in the inspector.

## Pulse amplitude relative to Energy (0.25 = ±25 %).
@export_range(0.0, 1.0, 0.05) var pulse_amount: float = 0.25
## Duration of one full pulse in seconds.
@export_range(0.1, 10.0, 0.1, "suffix:s") var pulse_period: float = 3.0
## Start each light at a random point of the pulse,
## so several anglerfish don't pulse in sync.
@export var random_phase: bool = true

## Energy set in the inspector; the pulse oscillates around it.
var _base_energy: float
## Current position in the pulse (radians).
var _t: float = 0.0


func _ready() -> void:
	_base_energy = energy
	if random_phase:
		_t = randf() * TAU


func _process(delta: float) -> void:
	_t += delta * TAU / pulse_period
	energy = _base_energy * (1.0 + pulse_amount * sin(_t))
