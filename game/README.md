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
art/boids/ Platzhalter-Grafik, Sprite-Sheet-Vorlage + Anleitung fürs Art-Team
obstacles/ obstacle (Basis), circle_obstacle, rect_obstacle + Szenen zum Reinziehen
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

## Aussehen der Boids (Art-Pipeline)

Ein Boid ist ein `Sprite2D` (`flock/boid.tscn`) mit einer Platzhalter-Pixelgrafik
(`art/boids/boid_placeholder.png`). Das Art-Team tauscht nur die PNG oder die `Texture` im
Inspector – am Code ändert sich nichts. Details und Regeln für die Grafiken:
`art/boids/README.md`.

* **Ausrichtung** (`facing_mode`): `ROTATE` (stufenlos drehen), `FLIP` (nur spiegeln, Seitenansicht),
  `DIRECTIONAL` (Sprite-Sheet mit z. B. 8 Richtungs-Frames; Spalten = Richtungen im Uhrzeigersinn ab Osten).
* **Animation:** Zeilen = Frames (`vframes`), `animation_fps` > 0.
* **Schwarmfarbe:** wird mit der Grafik multipliziert, `swarm_tint_strength` 1 = voll … 0 = Originalfarben.
* **Pixelart-Schärfe:** `texture_filter = Nearest` ist an der Boid-Szene gesetzt. Für das ganze Projekt:
  Projekteinstellungen → Rendering → Textures → *Default Texture Filter* = Nearest.
* **Verschiedene Looks:** geerbte Szene anlegen und `flock.spawn_swarm(pos, count, radius, szene)` nutzen.
* Ohne Textur zeichnet der Boid wieder den Vektorpfeil (Notbehelf).

Hinweis: Der Kamera-Zoom ist stufenlos (z. B. 0,6×). Bei Pixelart kann das leichte Unschärfe/Flimmern
einzelner Pixel geben; pixelgenaue Zoomstufen (0,5× / 1× / 2×) wären ein kleiner nächster Schritt.
Die Sprites sind bewusst bei 200 % Skalierung gesetzt, damit sie bei Zoom 0,6 gut erkennbar sind.

## Wo drehe ich was?

* Mehr/weniger Boids, Startpunkte, Weltgröße: `levels/level_01.tscn` (`boids_per_swarm`,
  `Marker2D`s unter `SwarmSpawns`, `world_rect`).
* Schwarm-Verhalten: `default_flock_settings.tres`.
* Zerreißen (Stärke, Dauer, Abstand): Export-Gruppe „Schwarm teilen“ am Level.
* Neuer Feldtyp für die Maus: Szene bauen, in `FieldPlacer` (`field_scenes` + `field_names`) eintragen.

## Erweiterungs-Rezepte (so getestet)

**Hindernis** – fertig eingebaut (`obstacles/`). Im Editor: `circle_obstacle.tscn` oder
`rect_obstacle.tscn` in die Level-Szene ziehen (unter `Obstacles`), `radius` bzw. `size` im
Inspector setzen, Rechtecke einfach drehen (`rotation`) – fertig. Boids weichen ab `margin`
weich aus und fließen an der Oberfläche entlang; zusätzlich schiebt eine harte Korrektur sie aus
dem Hindernis heraus, falls doch mal eins durchkommt (Test: 0 Boid-Frames im Inneren, kleinster
Abstand ≥ 35 px; ohne Hindernis liefen Boids bis ins Zentrum). Skalierung der Nodes bei 1 lassen.
Eine neue Form (Polygon, Kapsel …) = `Obstacle` erweitern und nur `surface_distance()`,
`surface_normal()` und `bounding_radius()` überschreiben.

**Hindernisse platzieren, Schritt für Schritt**

1. `levels/level_01.tscn` öffnen und den Node `Obstacles` auswählen.
2. `obstacles/circle_obstacle.tscn` (oder `rect_obstacle.tscn`) aus dem FileSystem-Dock auf `Obstacles` ziehen.
3. Mit dem Verschieben-Werkzeug (W) im 2D-Fenster platzieren. Im Inspector `Radius` bzw. `Size` und `Rotation` einstellen. Der Umriss ist im Editor sichtbar.
4. Starten (F5). Weitere Hindernisse: Node duplizieren (Strg+D).

Wichtig: Keine eigene Datei mit `class_name Obstacle` anlegen – die Klasse gibt es schon.
Per Code: `var o := preload("res://obstacles/circle_obstacle.tscn").instantiate(); o.radius = 150.0; o.position = Vector2(2000, 1500); $Obstacles.add_child(o)`

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

## Performance (Messwerte aus der Test-Umgebung: 1 CPU-Kern, ohne Grafik)

| Szenario | vorher | jetzt |
|---|---|---|
| 3 × 60 Boids | 6,1 ms | 2,7 ms |
| 3 × 200 Boids, Spawn-Radius 200 | 28 ms | 12 ms (+ Mehrkern-Verteilung, siehe unten) |
| 3 × 150, `steering_stride` 1 → 3 | – | 7,4 → 3,4 ms |

Was passiert ist: Daten liegen in Packed-Arrays statt in Node-Eigenschaften, das Raster ist ein
Counting-Sort ohne Dictionaries (3 zusammenhängende Bereiche pro Boid), und die Schwarm-Regeln
laufen auf dem `WorkerThreadPool` (`use_threads`). Threads liefern bit-identische Ergebnisse wie
Single-Thread (getestet); der Speed-up durch mehrere Kerne ließ sich in der Test-Umgebung nicht
messen, da sie nur einen Kern hat. Weitere Hebel, in dieser Reihenfolge:
`steering_stride` 2–3, `perception_radius` verkleinern (Kosten wachsen ~quadratisch),
Darstellung auf `MultiMeshInstance2D` umstellen (falls das Rendering von Tausenden Nodes bremst),
darüber hinaus C# / GDExtension.

## Warum Boids nicht mehr wackeln

Vorher: Cohesion/Separation benutzten `normalized()`. Ein Boid nahe am Schwerpunkt seiner Nachbarn
bekam dadurch Vollgas in eine fast zufällige Richtung, und die Separation sprang bei 34 px von
0 auf 100 %. Messung: 4,4° Richtungsänderung pro Frame, in 32 % der Frames Drehrichtungsumkehr.
Jetzt: Cohesion wirkt wie eine Feder (im Zentrum = 0), Separation wächst weich mit der Nähe,
Alignment gleicht an die mittlere Geschwindigkeit an, und die Darstellung dreht sich geglättet
(`turn_smoothing`). Messung: ~0,02–0,2° pro Frame, keine Umkehrungen. Neu: `swarm_bond_*` holt
Ausreißer weit weg vom Schwarm sanft zurück (greift im Normalfall nie).

## Automatisches Teilen (Schwarm zerfällt in neue Schwärme)

Zerfällt ein Schwarm durch ein Hindernis, ein Feld oder ein schwarzes Loch dauerhaft in mehrere
größere Teile, wird jedes Teil ein eigener Schwarm (eigene Farbe, eigener Zusammenhalt).
Technik: Boids des gleichen Schwarms, die näher als `fragment_link_radius` beieinander sind,
gelten als verbunden (Union-Find über das vorhandene Raster). Die Prüfung ist auf 8 Frames
verteilt und kostet praktisch nichts (600 Boids: 9,5 → 9,6 ms). Das größte Teil behält den
bisherigen Schwarm, jedes weitere bekommt einen neuen; Teile unter `fragment_min_size` Boids
schließen sich dem nächsten Teil an. Signal: `FlockManager.swarm_fragmented(original, new_swarms)`.

Einstellungen in `default_flock_settings.tres` (Gruppe „Automatisches Teilen“):

| Einstellung | Wirkung |
|---|---|
| `auto_split` | an/aus |
| `fragment_delay` (1,2 s) | so lange müssen die Teile getrennt bleiben. Höher = weniger Teilungen, kurzes Auseinanderfließen an einem Hindernis zählt nicht |
| `fragment_min_size` (8) | kleinere Teile werden nicht zum eigenen Schwarm |
| `fragment_link_radius` (80 px) | ab diesem Abstand sind Boids „getrennt“ |

Getestet: 90 s freier Flug ohne Hindernisse = 0 Fehlalarme (60 und 200 Boids pro Schwarm);
Schwarm frontal auf einen Kreis (r = 250): Teilung in 59 + 41; zwei gegenüberliegende Felder:
Schwarm wird in zwei neue Schwärme gerissen. Eine breite Wand bringt den Schwarm dagegen zum
Umdrehen statt zum Zerfallen – das hängt von Hindernisgröße und Schwarmbreite ab.
Wieder zusammenführen geht per Button/Taste M (`merge_nearby`); ein automatisches Vereinen wäre
der logische nächste Schritt.

## Bewusste Vereinfachungen

* Hindernisse sind Kreis und Rechteck (andere Formen: siehe oben, drei Funktionen).
* Schwärme teilen sich von selbst (siehe oben), vereinen sich aber nicht von selbst (nur per Button/`merge_nearby`).
* Boids sind einzelne Nodes mit `_draw()` – für mehrere Tausend später auf `MultiMeshInstance2D` umstellen.
