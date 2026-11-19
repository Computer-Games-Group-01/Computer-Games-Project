class_name Boid
extends Sprite2D
## Ein einzelner Boid: Zustand + Darstellung. Er IST der Sprite – die Grafik wird einfach
## im Inspector (oder durch Austausch der PNG-Datei) getauscht, am Code ändert sich nichts.
## Die Steuerung berechnet der FlockManager.
##
## Sprite-Konventionen (siehe art/boids/README.md):
##   * Grafik blickt nach RECHTS.
##   * Spalten (Hframes) = Blickrichtungen, im Uhrzeigersinn ab Osten (nur Modus DIRECTIONAL).
##   * Zeilen (Vframes) = Animations-Frames (laufen, wenn animation_fps > 0).

signal died(boid: Boid)

enum FacingMode {
	ROTATE,       ## Sprite dreht sich stufenlos in Flugrichtung (Standard)
	FLIP,         ## keine Drehung, nur nach links/rechts spiegeln (Seitenansicht)
	DIRECTIONAL,  ## je nach Flugrichtung die passende Spalte des Sprite-Sheets zeigen
}

@export var facing_mode: FacingMode = FacingMode.ROTATE
## Wie stark die Schwarmfarbe die Grafik einfärbt: 1 = voll, 0 = Originalfarben der Grafik.
@export_range(0.0, 1.0, 0.05) var swarm_tint_strength: float = 1.0
## Animations-Frames pro Sekunde (braucht Vframes > 1). 0 = keine Animation.
@export var animation_fps: float = 0.0
## Nur für den Vektor-Notbehelf, wenn keine Textur gesetzt ist.
@export var fallback_size: float = 13.0

var velocity: Vector2 = Vector2.ZERO
## Gesamtbeschleunigung des letzten Frames (nur zur Info/Debug).
var acceleration: Vector2 = Vector2.ZERO
## Anteil aus den Schwarm-Regeln (bleibt bei steering_stride > 1 zwischen den Updates erhalten).
var flock_accel: Vector2 = Vector2.ZERO
var swarm: Swarm = null
var max_speed: float = 210.0
var min_speed: float = 80.0
var alive: bool = true

## true = nur "drehen, keine Animation": der FlockManager setzt dann direkt die Rotation
## (schneller Pfad, spart pro Boid und Frame einen GDScript-Aufruf).
var simple_visual: bool = true

var _heading: float = 0.0
var _anim_time: float = randf() * 10.0  # zufälliger Start, damit nicht alle im Gleichtakt flattern


func _ready() -> void:
	simple_visual = texture == null \
			or (facing_mode == FacingMode.ROTATE and (animation_fps <= 0.0 or vframes <= 1))


## Schwarmfarbe anwenden (wird von Swarm.add() aufgerufen).
func apply_swarm_color(color: Color) -> void:
	modulate = Color.WHITE.lerp(color, swarm_tint_strength)


## Darstellung sofort auf die aktuelle Flugrichtung setzen (z. B. beim Spawnen).
func reset_visual() -> void:
	_heading = velocity.angle()
	update_visual(0.0, 1.0)


## Pro Frame vom FlockManager aufgerufen. turn_t = Glättung der Drehung (0..1).
func update_visual(delta: float, turn_t: float) -> void:
	_heading = lerp_angle(_heading, velocity.angle(), turn_t)

	if texture == null:  # Notbehelf: Vektorpfeil, dreht sich immer
		rotation = _heading
		return

	var col := 0
	match facing_mode:
		FacingMode.ROTATE:
			rotation = _heading
		FacingMode.FLIP:
			rotation = 0.0
			var c := cos(_heading)
			if c < -0.15:
				flip_h = true
			elif c > 0.15:
				flip_h = false
		FacingMode.DIRECTIONAL:
			rotation = 0.0
			col = posmod(roundi(_heading / (TAU / hframes)), hframes)

	var row := 0
	if vframes > 1 and animation_fps > 0.0:
		_anim_time += delta
		row = int(_anim_time * animation_fps) % vframes
	if col != frame_coords.x or row != frame_coords.y:
		frame_coords = Vector2i(col, row)


func _draw() -> void:
	if texture != null:
		return
	# Notbehelf ohne Textur: weißer Pfeil (Schwarmfarbe kommt über "modulate")
	var s := fallback_size
	draw_colored_polygon(PackedVector2Array([
		Vector2(s, 0.0), Vector2(-s * 0.7, -s * 0.55),
		Vector2(-s * 0.35, 0.0), Vector2(-s * 0.7, s * 0.55),
	]), Color.WHITE)


## Boid "stirbt" (schwarzes Loch, Gegner, Falle …). Entfernt wird er
## vom FlockManager am Ende des Frames.
func kill() -> void:
	if not alive:
		return
	alive = false
	died.emit(self)
