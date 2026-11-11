# Boids – Schwarm-Sandbox (Godot 4.7)

Start: Projekt öffnen → **F5** (Main-Szene `scenes/main.tscn` lädt `levels/level_01.tscn`).
Welt: 6400 × 3600 px, 3 Schwärme à 60 Boids an verschiedenen Startpunkten.

## Steuerung

| Eingabe | Wirkung |
|---|---|
| **Linksklick** | Gravitationsfeld setzen. **Ziehen** = Größe (Abstand zum Klickpunkt) |
| Rechtsklick | Feld unter dem Mauszeiger entfernen |
| **Q / E** (halten) | Feld unter dem Mauszeiger (sonst zuletzt gesetztes) kleiner / größer |
| **F** | Feldtyp wechseln: Gravitation ↔ Schwarzes Loch |
| **Space** / Button | Aktiven Schwarm halbieren – zwei Felder reißen die Hälften auseinander |
| **M** / Button | Nahe Schwärme wieder vereinen |
| **Tab** / Button | Nächsten Schwarm aktivieren (Kamera fährt hin, Ring markiert ihn) |
| WASD / Mausrad | Kamera / Zoom (zum Mauszeiger) |
| F3 | Debug-Overlay (Schwerpunkte, Wahrnehmungsradien) |

Hinweis: In deiner Input-Map ist Mausrad **hoch** = „zoom raus“. Fühlt sich das verkehrt an,
einfach die beiden Namen in den Projekteinstellungen tauschen.
Neu in der Input-Map: `Feld entfernen`, `Feld größer`, `Feld kleiner`, `Feldtyp wechseln`,
`Schwarm teilen`, `Schwarm vereinen`, `Schwarm wechseln`.

## Aufbau

```
core/      influencer.gd (Basisklasse!), camera_controller.gd
flock/     boid, swarm, flock_manager, flock_settings (+ .tres), Szenen
fields/    gravity_field, black_hole, field_placer (Maussteuerung), Szenen
levels/    level.gd (verdrahtet alles), level_01.tscn
ui/        hud
scenes/    main.tscn
enemies/, tools/, art/, assets/, addons/   – noch leer, bereit für später
```

## Wie es funktioniert

* **Boids** sind schlichte `Node2D`s (Zustand + Zeichnung). Der **FlockManager** rechnet pro Frame
  für alle: Separation (von allen), Alignment + Cohesion (nur eigener **Swarm**), Weltgrenzen
  und zuletzt alle **Influencer**. Nachbarn werden über ein Raster (Spatial Hash) gefunden.
* **Swarm** ist nur eine Gruppe von Boids. *Teilen* = Boids wechseln in einen neuen Swarm,
  *Vereinen* = umgekehrt. Dadurch ist das Zerreißen simpel: Jede Hälfte bekommt ein eigenes Feld
  (`target_swarm`), das nur auf sie wirkt.
* **Influencer** (`core/influencer.gd`) ist *der* Erweiterungspunkt: alles, was Boids schiebt,
  ist ein Node in der Gruppe `influencers` mit `get_force_on(boid)` und `get_reach()`.
  Der FlockManager kennt keine konkreten Typen.
* **GravityField**: `radius` (Größe), `strength`, `orbit_ratio` (Ringradius als Anteil, 0 = alles
  zum Zentrum), `swirl` (0 = nur anziehen, 1 = kreisen), `clockwise`, `lifetime`
  (0 = dauerhaft), `removable`. Weit draußen zieht es direkt hinein, nahe am Ring gehen die Boids
  ins Kreisen über.
* **FlockSettings** (`flock/default_flock_settings.tres`): Geschwindigkeit, Wahrnehmung,
  Gewichte, Weltrand, Performance. Im Inspector live änderbar.

## Wo drehe ich was?

* Mehr/weniger Boids, Startpunkte, Weltgröße: `levels/level_01.tscn` (`boids_per_swarm`,
  `Marker2D`s unter `SwarmSpawns`, `world_rect`).
* Schwarm-Verhalten: `default_flock_settings.tres`.
* Zerreißen (Stärke, Dauer, Abstand): Export-Gruppe „Schwarm teilen“ am Level.
* Neuer Feldtyp für die Maus: Szene bauen, in `FieldPlacer` (`field_scenes` + `field_names`) eintragen.

## Erweiterungs-Rezepte (so getestet)

**Hindernis** – `fields/obstacle.gd` (weiche Abstoßung; im Test kamen Boids ohne Hindernis bis auf
3 px ans Zentrum, mit Hindernis nie näher als 133 px bei Radius 120):

```gdscript
class_name Obstacle
extends Influencer

@export var radius: float = 120.0
@export var margin: float = 120.0
@export var strength: float = 1800.0

func get_reach() -> float:
	return radius + margin

func get_force_on(boid: Boid) -> Vector2:
	var away := boid.global_position - global_position
	var d := maxf(away.length(), 0.001)
	var t := 1.0 - clampf((d - radius) / margin, 0.0, 1.0)
	return away / d * strength * t

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.5, 0.5, 0.55))
```

**Gegner** – `enemies/hunter.gd` (jagt den nächsten Schwarm, scheucht Boids, frisst nahe Boids;
Werte so, dass er einige erwischt, aber nicht alle):

```gdscript
class_name Hunter
extends Influencer

@export var speed: float = 160.0
@export var kill_radius: float = 36.0
@export var scare_radius: float = 260.0
@export var scare_force: float = 300.0
var flock: FlockManager   # beim Erzeugen setzen: hunter.flock = $FlockManager

func get_reach() -> float:
	return scare_radius

func _process(delta: float) -> void:
	if flock == null or flock.swarms.is_empty():
		return
	var best := flock.swarms[0].centroid()
	for s in flock.swarms:
		if s.centroid().distance_to(global_position) < best.distance_to(global_position):
			best = s.centroid()
	global_position += (best - global_position).limit_length(speed * delta)

func get_force_on(boid: Boid) -> Vector2:
	var away := boid.global_position - global_position
	var d := away.length()
	if d < kill_radius:
		boid.kill()
		return Vector2.ZERO
	return away / maxf(d, 0.001) * scare_force * (1.0 - d / scare_radius)
```

**Schwarze Löcher** – gibt es schon: `fields/black_hole.tscn` in ein Level legen,
`removable = false` setzen, fertig. Es zieht je näher desto stärker und verschluckt am Kern
(`boid.kill()`; Signal `FlockManager.boid_died` für Punktestand o. Ä.).

**Rätsel-Bausteine**, die schon da sind:
`influencer.enabled` (Schalter), `target_swarm` (Feld wirkt nur auf einen Schwarm),
`removable = false` (feste Felder), `lifetime` (temporäre Felder),
`flock.get_boids_in_circle(pos, radius)` (Zielzonen: „bring 40 Boids hierher“),
`flock.split_swarm()` / `merge_nearby()`.

## Performance (Messwerte aus der Test-Umgebung, ohne Grafik)

| Boids | Zeit pro Frame |
|---|---|
| 180 (Standard) | ~3,5 ms |
| ~1000, `steering_stride = 1` | ~50 ms |
| ~1000, `steering_stride = 3` | ~18 ms |

Auf deinem Rechner wird es anders aussehen. Reicht es nicht: `steering_stride` erhöhen,
`perception_radius` verkleinern; darüber hinaus Berechnung nach C# / GDExtension auslagern.

## Bewusste Vereinfachungen

* Hindernisse sind weiche Kräfte, keine harten Kollisionen.
* Schwärme vereinen sich nicht von selbst (nur per Button/`merge_nearby`).
* Boids sind einzelne Nodes mit `_draw()` – für mehrere Tausend später auf `MultiMeshInstance2D` umstellen.
