# Boid-Grafiken – Anleitung für das Art-Team

Aktuell liegt hier ein **Platzhalter** (`boid_placeholder.png`, 16×16 px) und eine **Vorlage**
für Sprite-Sheets (`boid_sheet_template_8dir_2frames.png`, 8 Richtungen × 2 Animations-Frames).

## Regeln für die Grafik

* PNG, transparenter Hintergrund, **Pixelart** (harte Kanten, keine Weichzeichnung).
* Die Figur **blickt nach rechts** (Osten).
* Größe: Platzhalter ist 16×16 px, im Spiel auf 200 % skaliert (Scale im `boid.tscn`),
  also ca. 24 × 16 Spielpixel. Andere Größen sind möglich – danach `separation_radius`
  in `flock/default_flock_settings.tres` anpassen (etwas größer als die Sprite-Breite).
* **Farbe:** Jeder Schwarm hat eine Farbe, die mit der Grafik multipliziert wird. Darum
  Körper in **hellem Grau/Weiß** zeichnen; dunkle Pixel bleiben dunkel (Umriss, Auge).
  Soll die Grafik ihre eigenen Farben behalten: `Swarm Tint Strength` = 0 setzen
  (dann sind Schwärme nur noch am Verhalten unterscheidbar; Alternative: Outline-Shader, siehe Entwickler).

## So tauschst du die Grafik (ohne Code)

**Einfachste Variante:** `boid_placeholder.png` durch eine eigene Datei **mit gleichem Namen** ersetzen.

**Per Inspector:** `flock/boid.tscn` öffnen → Node `Boid` auswählen →
`Texture` auf die neue PNG ziehen. Für Sheets unter *Animation*: `Hframes` = Spalten,
`Vframes` = Zeilen. Ausrichtung/Animation stehen oben im Inspector unter dem Skript-Namen.

## Ausrichtungs-Modi (`Facing Mode`)

| Modus | Wann | Sheet-Layout |
|---|---|---|
| `ROTATE` | einfach: Sprite dreht sich stufenlos in Flugrichtung (bei Pixelart etwas „kantig“) | 1 Spalte |
| `FLIP` | Seitenansicht (Fisch, Vogel von der Seite): nur links/rechts spiegeln, keine Drehung | 1 Spalte |
| `DIRECTIONAL` | sauberste Pixelart: pro Richtung ein handgemaltes Frame | `Hframes` Spalten = Richtungen, **im Uhrzeigersinn ab Osten** (bei 8: O, SO, S, SW, W, NW, N, NO) |

**Animation:** Zeilen des Sheets = Frames (`Vframes`). `Animation Fps` > 0 startet sie
(jeder Boid mit zufälligem Startpunkt). Das Template zeigt das Layout: Spalten = Richtung, Zeile 0/1 = Flügel oben/unten.

## Verschiedene Looks (z. B. Gegner-Schwarm)

`boid.tscn` → *Szene → Neue geerbte Szene*, andere Textur/Modus setzen, speichern.
Der Entwickler übergibt sie beim Erzeugen: `flock.spawn_swarm(pos, 40, 100.0, preload("res://…"))`.
