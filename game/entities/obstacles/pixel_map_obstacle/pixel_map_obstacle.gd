@tool
class_name PixelMapObstacle
extends Obstacle

## Deine gezeichnete PNG-Map (Transparent = frei, Undurchsichtig = Wand/Hindernis)
@export var map_texture: Texture2D:
	set(value):
		map_texture = value
		_rebuild_sdf()
		queue_redraw()
		update_configuration_warnings() 

## Wie viele Spiel-Pixel einem Bild-Pixel entsprechen (z.B. 4.0 bei Pixel-Art)
@export var pixel_scale: float = 4.0:
	set(value):
		pixel_scale = maxf(value, 0.1)
		queue_redraw()

## Schwellenwert für Alpha: Ab diesem Deckkraft-Wert gilt ein Pixel als Wand
@export_range(0.01, 1.0) var alpha_threshold: float = 0.5:
	set(value):
		alpha_threshold = value
		_rebuild_sdf()

## Soll die PNG-Map auch direkt von diesem Node gezeichnet werden?
@export var draw_texture: bool = true:
	set(value):
		draw_texture = value
		queue_redraw()
		
## Background image below the walls. Same pixel size as map_texture,
## scaled and centred the same way.
@export var background_texture: Texture2D:
	set(value):
		background_texture = value
		queue_redraw()

var _w: int = 0
var _h: int = 0
var _sdf := PackedFloat32Array() # Speichert den Abstand zur Wand in Bild-Pixeln


func _ready() -> void:
	super._ready()
	if map_texture != null and _sdf.is_empty():
		_rebuild_sdf()


func bounding_radius() -> float:
	if _w == 0 or _h == 0:
		return 0.0
	# Umschließt die gesamte Map (zentriert um Node-Position)
	return Vector2(_w, _h).length() * 0.5 * pixel_scale


func surface_distance(world_point: Vector2) -> float:
	if _sdf.is_empty():
		return INF
	var p := _world_to_grid(world_point)
	# Außerhalb des Bildes: Abstand zum Bildrand + geschätzter Abstand
	if p.x < 0.0 or p.y < 0.0 or p.x >= _w - 1 or p.y >= _h - 1:
		var clamped := p.clamp(Vector2.ZERO, Vector2(_w - 1, _h - 1))
		return (_sample_sdf(clamped) + p.distance_to(clamped)) * pixel_scale
	return _sample_sdf(p) * pixel_scale


func surface_normal(world_point: Vector2) -> Vector2:
	if _sdf.is_empty():
		return Vector2.UP
	var p := _world_to_grid(world_point).clamp(Vector2(1, 1), Vector2(_w - 2, _h - 2))
	# Gradient (Steigung) des Distanzfeldes zeigt immer exakt von der Wand weg
	var dx := _sample_sdf(p + Vector2(1.0, 0.0)) - _sample_sdf(p - Vector2(1.0, 0.0))
	var dy := _sample_sdf(p + Vector2(0.0, 1.0)) - _sample_sdf(p - Vector2(0.0, 1.0))
	var grad := Vector2(dx, dy)
	if grad.length_squared() < 0.00001:
		return Vector2.UP
	return global_transform.basis_xform(grad.normalized()).normalized()


# --- Hilfsfunktionen für Koordinaten & Interpolation ---

func _world_to_grid(world_point: Vector2) -> Vector2:
	var local := to_local(world_point)
	return (local / pixel_scale) + Vector2(_w, _h) * 0.5


func _sample_sdf(p: Vector2) -> float:
	# Bilineare Interpolation für weiche Übergänge zwischen Pixeln (kein Treppeneffekt)
	var x0 := clampi(int(floor(p.x)), 0, _w - 2)
	var y0 := clampi(int(floor(p.y)), 0, _h - 2)
	var fx := p.x - x0
	var fy := p.y - y0

	var d00 := _sdf[y0 * _w + x0]
	var d10 := _sdf[y0 * _w + x0 + 1]
	var d01 := _sdf[(y0 + 1) * _w + x0]
	var d11 := _sdf[(y0 + 1) * _w + x0 + 1]

	return lerpf(lerpf(d00, d10, fx), lerpf(d01, d11, fx), fy)


func _draw() -> void:
	var size := Vector2(_w, _h) * pixel_scale
	if background_texture != null:
		draw_texture_rect(background_texture, Rect2(-size * 0.5, size), false)
	if draw_texture and map_texture != null:
		draw_texture_rect(map_texture, Rect2(-size * 0.5, size), false)


func _get_configuration_warnings() -> PackedStringArray:
	if map_texture == null:
		return PackedStringArray(["map_texture is missing: without a wall image there is no collision."])
	return PackedStringArray()

# --- Berechnung des Signed Distance Fields (Chamfer Distance Transform) ---

func _rebuild_sdf() -> void:
	if map_texture == null:
		_sdf.clear()
		_w = 0
		_h = 0
		return

	var img := map_texture.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()

	_w = img.get_width()
	_h = img.get_height()
	var n := _w * _h
	var solid_mask := PackedByteArray()
	solid_mask.resize(n)

	for y in _h:
		for x in _w:
			var is_wall := img.get_pixel(x, y).a >= alpha_threshold
			solid_mask[y * _w + x] = 1 if is_wall else 0

	var dist_out := _compute_distance_field(solid_mask, false) # Abstand zum nächsten Hindernis
	var dist_in := _compute_distance_field(solid_mask, true)   # Abstand nach draußen (falls Boid innen)

	_sdf.resize(n)
	for i in n:
		_sdf[i] = dist_out[i] - dist_in[i]


func _compute_distance_field(mask: PackedByteArray, invert: bool) -> PackedFloat32Array:
	var n := _w * _h
	var d := PackedFloat32Array()
	d.resize(n)
	var inf := float(_w + _h) * 2.0
	var target := 0 if invert else 1

	for i in n:
		d[i] = 0.0 if mask[i] == target else inf

	var diag := 1.41421356
	# Vorwärts-Durchlauf
	for y in _h:
		for x in _w:
			var idx := y * _w + x
			var v := d[idx]
			if x > 0:
				v = minf(v, d[idx - 1] + 1.0)
			if y > 0:
				v = minf(v, d[idx - _w] + 1.0)
				if x > 0:
					v = minf(v, d[idx - _w - 1] + diag)
				if x < _w - 1:
					v = minf(v, d[idx - _w + 1] + diag)
			d[idx] = v

	# Rückwärts-Durchlauf
	for y in range(_h - 1, -1, -1):
		for x in range(_w - 1, -1, -1):
			var idx := y * _w + x
			var v := d[idx]
			if x < _w - 1:
				v = minf(v, d[idx + 1] + 1.0)
			if y < _h - 1:
				v = minf(v, d[idx + _w] + 1.0)
				if x < _w - 1:
					v = minf(v, d[idx + _w + 1] + diag)
				if x > 0:
					v = minf(v, d[idx + _w - 1] + diag)
			d[idx] = v

	return d
