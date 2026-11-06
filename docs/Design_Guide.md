# Design-Dokument – Idee 3 (Fractured Gravity)

Nov 6, 2026 · @Leon

## Über dieses Dokument

Dieses Dokument ist die zentrale Anlaufstelle für alle Fragen, die beim Umsetzen der Tasks auftauchen. Es fasst den Stand des FigJam-Boards „GamePlan-Idee3“ und unser Konzeptdokument zusammen (Stand 06.11.2026).

Die Gliederung folgt den Bereichen auf dem Board: Basis, 1. Prototyp, Mindestliste, Wunschliste, Ideen zur Inspiration. Am Ende stehen alle offenen Entscheidungen, die Technik-Referenzen und ein Glossar.

**Legende**

- **Entschieden:** vom Team auf dem Board festgelegt.
- **Offen:** muss noch entschieden werden. Alle offenen Punkte stehen zusätzlich gesammelt im Abschnitt „Offene Entscheidungen“.
- **Vorschlag:** Empfehlung aus der Ausarbeitung, vom Team noch nicht bestätigt.

**Arbeitsregel:** Taucht beim Umsetzen eine Frage auf, die hier nicht beantwortet ist, tragt sie als offene Frage ein, statt still selbst zu entscheiden. Wer etwas entscheidet, ändert „Offen“ zu „Entschieden“ und schreibt kurz das Datum dazu.

### Zeitplan

&#91;embedded content: Meilensteine · Okt 2026 bis Mär 2027\]

Phase 1 endet mit der Final Presentation am 09.02. (Abgabe: README, Pitch, 30-Sekunden-Trailer, spielbare Demo). Bis zum Playtest am 09.03. muss das Spiel voll spielbar sein. Vor jedem Meeting erscheint am Vortag ein Devlog auf Discord, als Nächstes am 16.11.

## Basis

Kern-Satz: **Wir steuern nicht den Schwarm, sondern die Schwerkraft.** Der Schwarm bewegt sich selbstständig nach dem Boids-Algorithmus, der Spieler lenkt ihn nur indirekt über Gravity Fields.

| Thema | Stand | Festlegung bzw. Optionen |
| --- | --- | --- |
| Kern-Satz | Entschieden | Steuerung der Schwerkraft statt des Schwarms. Der Spieler ist nicht Teil des Schwarms (Jakob: den chaotischen Schwarm „bändigen“). |
| Genre | Entschieden | Echtzeit-Strategie mit Rätseln und Gegnern. Kein Präzisions-Puzzle: Taktik und Reaktion zählen mehr als perfekte Platzierung. |
| Theme | Entschieden (06.11.) | Unterwasser, der Spieler lenkt einen Fischschwarm. |
| Perspektive | Entschieden (06.11.) | 2D-Seitenansicht. Eine natürliche Schwerkraft nach unten gibt es nicht: Die Fische schweben frei im Wasser, es wirken nur die Fields des Spielers. |
| Kamera | Entschieden | Freie Kamera: Bewegen mit WASD, Zoomen. |
| Engine & Code | Entschieden (06.11.) | Godot 4.7, 2D, GDScript. Neues Projekt; der alte C#-Prototyp wird nicht portiert. |
| Ziel | Entschieden, vorerst (06.11.) | Möglichst viele Boids ins Ziel bringen. |
| Gegner | Entschieden (06.11.) | Gegner gehören in den Prototyp. Für das Meeting am 17.11. reicht ein Minimalprototyp ohne Gegner. |
| Technischer Anker | Entschieden, vorerst (06.11.) | Reinforcement Learning für die Gegner. |
| Ton | Entschieden (06.11.) | Eher fordernd. |
| Spielform | Offen | Vorschlag: Singleplayer, PC mit Maus und Tastatur. |
| Verlieren | Offen | Was passiert, wenn alle Boids sterben? Gibt es eine Mindestzahl, die ankommen muss? |

**Rahmen des Kurses:** Computerspiele & Visual Effects 1+2, Steam-Ready-Track (12 ECTS), Thema *Fractured Gravity*. Vor jedem Betreuer-Meeting erscheint am Vortag ein Devlog auf Discord. Meetings: 10 Minuten Showcase, 10 Minuten Feedback, eigene Fragen an die Betreuer mitbringen. Bewertung: 60 % Betreuer, 40 % Peer-Bewertung im Team.

**Bezug zu Fractured Gravity:** Unter Wasser gibt es keine Schwerkraft nach unten – die einzige Schwerkraft sind die Felder, die der Spieler setzt. Gegenüberliegende oder abstoßende Felder zerreißen den Schwarm; das „Fractured“ entsteht direkt aus der Simulation.

## Team und Rollen (Sprint bis 17.11.)

Für den Sprint bis zum Prototyp-Meeting am 17.11. gibt es vier Rollen. Wer welche Rolle übernimmt, steht noch nicht im Dokument; auf dem Board liegen die Rollen im Bereich „Team“.

| Rolle | Personen | Aufgaben im Sprint |
| --- | --- | --- |
| Scrum Master | 1 | GitHub-Projekt und Issues pflegen, Aufgaben zuweisen, Docs (dieses Dokument) aktuell halten, Devlog schreiben (nächstes am 16.11.) |
| Art | 2 | Designsprache und Stil, Farbpalette, Boid-Design, mögliches Leveldesign, Mechanikendesign, UI |
| Devs | 2 | Neues Godot-Projekt aufsetzen, Minimalprototyp ohne Gegner für das Meeting am 17.11. |
| Reinforcement Learning | 1, teilweise unterstützt vom Scrum Master | Research; den RL-Gegner zunächst außerhalb des Hauptprojekts lauffähig machen |

**Schnittstellen zwischen den Rollen**

- **Art → Devs:** Farbpalette und Boid-Design früh als Platzhalter liefern, damit der Prototyp am 17.11. schon nach Unterwasser aussieht. Vorschlag: eine gemeinsame Datei mit den Farbwerten im Projekt.
- **RL → Devs:** Vor der Integration eine gemeinsame Gegner-Schnittstelle festlegen: was ein Gegner wahrnimmt (z. B. Schwarmzentrum, nächste Boids, Wände) und was er tun kann (z. B. Bewegungsrichtung oder Schwarm-Parameter). Dann lässt sich der RL-Gegner später ohne Umbau einsetzen. Details siehe „Gegner im Prototyp“.
- **Art und Mechanikendesign:** Entscheidungen zu Mechaniken hier im Dokument eintragen, damit Devs und RL sie sehen.
- **Scrum Master:** Jeder Task im GitHub-Board verweist auf den passenden Abschnitt dieses Dokuments.
- **Offen:** Wer übernimmt welche Rolle? Wer kümmert sich später um Outreach (Website, Trailer)?

## 1. Prototyp (bis 17.11.)

Der Prototyp muss zeigen, dass indirektes Steuern über Gravity Fields Spaß macht. Am 17.11. soll der Game Loop final sein; dazu gehören auch Projektleitung und GitHub-Board.

**Testfrage des Prototyps:** Macht es Spaß, einen Schwarm nur über Schwerkraft durch einen Abschnitt zu lenken und ihn dabei gezielt aufzuteilen?

**Entscheidungen vom 06.11.:**

- Theme Unterwasser, 2D-Seitenansicht, ohne natürliche Schwerkraft nach unten.
- Ziel: möglichst viele Boids ins Ziel bringen.
- Gegner gehören zum Prototyp. Für das Meeting am 17.11. bauen die Devs einen Minimalprototyp ohne Gegner; der RL-Gegner entsteht parallel außerhalb des Hauptprojekts.
- Neues Godot-Projekt in GDScript, kein Port des alten C#-Prototyps.

### Umfang

| Drin bis 17.11. | Nicht drin |
| --- | --- |
| Ein Fischschwarm, ein Unterwasser-Test-Abschnitt in Seitenansicht mit Start, Ziel und Hindernissen | Gegner – kommen nach dem Meeting dazu, siehe „Gegner im Prototyp“ |
| Gravity Field per Klick, läuft nach Zeit ab | Items, Fog of War, Spurfeld |
| Aufteilen über zwei gegenüberliegende Fields | Commander / Informed Individuals, GPU-Schwarm, Level-Generierung |
| Freie Kamera (WASD, Zoom) | Story, finaler Look, Sound |
| Tuning-Werte im Editor, Debug-Overlay, erste Farbpalette und Boid-Design von Art | Savezones mit Sortieren |

### Steuerung: Gravity Field

- **Entschieden:** Ein Klick erzeugt ein Gravity Field. Boids in der Nähe werden angezogen und versuchen, den Punkt zu erreichen.
- **Entschieden:** Das Field wirkt nur lokal (fester Radius). So lassen sich getrennte Schwärme einzeln lenken.
- **Entschieden:** Das Field läuft nach einer bestimmten Zeit ab.
- **Entschieden:** Der Schwarm reagiert in Echtzeit, der Spieler steuert laufend nach.
- **Bekannte Einschränkung:** Wird nur ein Teil einer Gruppe angezogen, folgt durch das Boids-Verhalten meist die ganze Gruppe.
- **Offen:** Wie viele Fields gleichzeitig? Gibt es einen Cooldown? (Jakob schlug Cooldown vor.)
- **Offen:** Wird die Anziehung mit kürzerer Entfernung stärker?

**Bekanntes technisches Problem (Ariusha):** „Je näher, desto stärker“ wirkt mit dem aktuellen Algorithmus kaum. Weiter entfernte Boids folgen ihren Nachbarn mit gleicher Geschwindigkeit. Lösungsansätze:

1. Field-Kraft nur innerhalb des Radius anwenden und mit der Entfernung abfallen lassen.
2. Alignment-Gewicht senken oder während eines aktiven Fields reduzieren, damit Nachbarn den Effekt nicht glätten.
3. Zum Feature machen: Nur „informierte“ Boids spüren das Field, der Rest folgt ihnen (Couzin-Prinzip, siehe Mindestliste).

### Kamera

- **Entschieden:** Freie Kamera, Bewegen mit WASD, Zoom (z. B. Mausrad).
- **Offen:** Zoom per Mausrad kollidiert mit der Idee, die Field-Stärke per Mausrad einzustellen (Mindestliste). Eine Belegung muss weichen.

### Aufteilen des Schwarms

- **Entschieden (Variante A):** Zwei gegenüberliegende Fields ziehen den Schwarm auseinander. Der Split entsteht aus der Simulation, nicht per Knopf.
- **Fallback (Variante B):** Ein Button zum Aufteilen, falls Variante A sich nicht kontrollierbar anfühlt.
- **Vorschlag:** Janas abstoßende Gravitationsfelder (Mindestliste) als dritte Variante testen. Ein abstoßendes Field mitten im Schwarm teilt ihn ohne zweites Field.
- **Hintergrund (Couzin-Effekt):** Werden zwei Hälften in verschiedene Richtungen gezogen, entsteht bei kleinem Winkel ein Kompromiss. Bei großem Winkel teilt sich der Schwarm oder schnappt zu einer Seite. Das ist günstig umzusetzen und zitierbar ([Couzin et al. 2005](https://www.nature.com/articles/nature03236), [Demo](https://www.complexity-explorables.org/)).

### Gegner im Prototyp

Gegner kommen in den Prototyp, aber erst nach dem Meeting am 17.11. Bis dahin entwickelt die RL-Rolle den Gegner außerhalb des Hauptprojekts.

- **Ansatz (Vorschlag):** Ein KI-Commander steuert den Gegner bzw. Gegnerschwarm. Er entscheidet alle paar Sekunden über wenige Werte, die Boids führen sie aus. Das trainiert stabiler als ein eigener Agent pro Boid.
- **Zuerst handgeschrieben:** Die Devs bauen den Gegner mit einfacher Regel-Logik hinter derselben Schnittstelle. Der RL-Gegner ersetzt sie später ohne Umbau.
- **Verhalten (vorläufig, aus der Mindestliste):** Gegner töten Boids bei Kontakt, ihre Stärke zeigt sich an der Größe. Unter Wasser z. B. Raubfische.

**Gegner-Schnittstelle (Vorschlag, zwischen RL und Devs abstimmen):**

| Teil | Inhalt |
| --- | --- |
| Wahrnehmung | Position und Größe des Spielerschwarms, Abstand zu den nächsten Boids, Wände in der Nähe, eigene Größe |
| Aktionen | Zielpunkt bzw. Bewegungsrichtung, Zusammenhalt, Aggressivität |
| Belohnung im Training | Plus für getötete Boids, Minus für eigene Verluste |

- **Training:** Mit Godot RL Agents, in Python lokal auf dem eigenen PC; das Spiel läuft dabei beschleunigt. Für das Training braucht es einen einfachen Bot, der den Spieler simuliert.
- **Im fertigen Spiel:** ONNX braucht die .NET-Version des Editors. Alternative: Godot Native RL (ohne C#, Community-Addon v0.4.0). Früh testen, welcher Weg mit dem GDScript-Projekt funktioniert.
- **Offen:** Kann sich der Schwarm wehren oder nur fliehen? Ein Gegnertyp oder mehrere?

### Technische Vorgaben für den Prototyp

- Ein Flock-Manager hält alle Boids in parallelen Arrays (Position, Geschwindigkeit, Werte pro Boid). Keine eigenen Nodes pro Boid.
- Rendering aller Boids über ein `MultiMeshInstance2D`, Transformationen in einem einzigen Aufruf hochladen.
- Nachbarsuche über ein Spatial Grid (Zellgröße = Sichtradius), nicht jeder gegen jeden.
- Alle Tuning-Werte als `@export` im Editor: Separation, Alignment, Cohesion, Sichtradius, Maximalgeschwindigkeit, Field-Stärke, Field-Radius, Field-Dauer.
- Debug-Overlay zum Ein- und Ausblenden: Field-Radien, Sichtradius, Schwarmzentrum, Boid-Anzahl, Framezeit.
- **Entschieden (06.11.):** Neues Projekt, der alte C#-Prototyp wird nicht portiert.

### Abnahme bis 17.11.

- [ ] **Devs:** Neues Godot-Projekt aufgesetzt und im GitHub-Repo.
- [ ] **Devs:** Ein Klick setzt ein Field, Boids im Radius werden sichtbar angezogen, das Field verschwindet nach der eingestellten Zeit.
- [ ] **Devs:** Zwei gegenüberliegende Fields teilen den Schwarm reproduzierbar in zwei Gruppen.
- [ ] **Devs:** Kamera bewegt sich mit WASD und zoomt.
- [ ] **Devs:** Ein Unterwasser-Test-Abschnitt in Seitenansicht mit Start, Ziel und mindestens zwei Hindernissen ist spielbar.
- [ ] **Devs:** Anzeige: gestartete und am Ziel angekommene Boids.
- [ ] **Devs:** 300 Boids laufen flüssig (Ziel: 60 fps).
- [ ] **Art:** Erste Farbpalette, Boid-Design und Stilrichtung für Unterwasser.
- [ ] **RL:** Research-Ergebnis und ein erster lauffähiger Test außerhalb des Hauptprojekts.
- [ ] **Scrum Master:** GitHub-Board mit Issues und Zuweisungen; Devlog für den 16.11.; Fragen an die Betreuer gesammelt.

## Mindestliste (Demo 09.02.)

Alles hier muss in der spielbaren Demo zur Final Presentation am 09.02. stecken. Die Liste ist auf höchstens 8–10 Punkte begrenzt; was nicht reinpasst, kommt auf die Wunschliste.

**Abgabe am 09.02.:** GitHub-README, Pitch, 30-Sekunden-Trailer, spielbare Demo. Zwischenstände: 01.12. erstes Blocking und Gliederung des ganzen Spiels, 12.01. komplette Demo im Blockout.

**Achtung Umfang:** Im Bereich „Mindestliste“ liegen inzwischen rund 25 Notes, deutlich mehr als die vereinbarten 8–10. Vor allem Level-Generierung und die Fortschritts-Modelle sind neu hinzugekommen.

### Gefahren

Es gibt zwei Arten von Gefahren: stationäre Gefahren und Gegner.

**Stationäre Gefahren**

- **Entschieden:** Feste Gefahren im Level, tödlich für alle Boids – eigene und gegnerische. Dadurch kann man Gegner auch in Gefahren locken.
- **Offen:** Welche konkreten Gefahren? Theme ist Unterwasser – Kandidaten: Angelhaken, Fischernetze, Ölflecken, Abwasserrohre.

**Gegner**

- **Entschieden:** Gegner sind eine eigene Mechanik.
- **Vorläufig (auf dem Board in Klammern):** Gegner sind ebenfalls Boids. Sie folgen der Spur des Schwarms oder bewegen sich zufällig und töten Boids bei Kontakt. Ihre Stärke zeigt sich an ihrer Größe: Ein Gegner tötet je nach Stärke eine bestimmte Anzahl Boids, bevor er selbst stirbt. Der Spieler weicht aus oder lockt Gegner in Fallen.
- **Offen:** Können Boids angreifen oder nur fliehen?
- **Offen:** Folgen Gegner der Spur (setzt das Spurfeld voraus) oder bewegen sie sich zufällig?
- **Vorschlag:** Für die Demo genau einen Gegnertyp bauen. Weitere Typen kommen auf die Wunschliste. Der Gegner wird per Reinforcement Learning gesteuert (technischer Anker), siehe „Gegner im Prototyp“.

### Hindernisse

- **Entschieden:** Hindernisse gehören in die Demo (Board-Note „Hindernisse“).
- **Offen:** Welche Hindernisse genau? Ideen stehen in der Wunschliste; fast alle passen bereits zu Unterwasser.
- **Vorschlag:** Mindestens ein Hindernis, für das man den Schwarm aufteilen muss (z. B. ein Teilschwarm hält einen Knopf, der andere geht durchs Tor), und eine enge Passage, durch die nur ein kleiner Schwarm passt.

### Field-Eigenschaften (optional)

- Stärke und Radius eines Fields sind einstellbar, z. B. per Mausrad, ebenso die Dauer bis zum Verschwinden.
- **Offen:** Mausrad ist bereits für den Kamera-Zoom vorgesehen. Alternative: Taste gedrückt halten und Mausrad, oder Klick gedrückt halten, um ein Field aufzuladen.

### Abstoßende Gravitationsfelder

- **Idee (Jana):** Neben anziehenden auch abstoßende Fields.
- **Damit verbunden (Frederik):** Den Schwarm zusammenquetschen, damit er durch einen Spalt passt – zwei abstoßende Fields von außen drücken ihn schmal.
- Abstoßende Fields mitten im Schwarm sind außerdem eine einfache Art, ihn aufzuteilen (siehe 1. Prototyp).

### Performance

Große Schwärme brauchen Performance-Optimierungen. Für die CPU in GDScript gilt:

1. Spatial Grid für die Nachbarsuche, gebaut aus flachen Arrays statt Dictionaries.
2. Nachbarn pro Boid begrenzen (etwa 7–10). Stare orientieren sich an etwa 6–7 Nachbarn, das ist auch biologisch begründet.
3. Distanzen quadriert vergleichen, keine Wurzel nur für den Radius-Check.
4. Alle Transformationen in einem Aufruf an das MultiMesh übergeben (`RenderingServer.multimesh_set_buffer`).
5. Keine Physik-Abfragen und keine Nodes pro Boid; Hindernisse über ein Distanzfeld abfragen.
6. Keine Speicher-Allokationen pro Frame; Arrays auf Maximalgröße vorbelegen.
7. Nur bei Bedarf: Steuerung nur für einen Teil der Boids pro Frame neu berechnen (Time-Slicing).

GDScript schafft mit Grid etwa einige hundert Boids flüssig, 1.000 mit Sorgfalt. Für mehrere tausend Boids braucht es den GPU-Schwarm (Wunschliste). Früh messen!

### Technischer Anker

- **Entschieden, vorerst (06.11.):** Der technische Anker ist Reinforcement Learning für die Gegner. Laut Betreuer-Feedback reicht Boids allein nicht.
- **Umsetzung:** Zunächst außerhalb des Hauptprojekts (Rolle RL), Integration über die Gegner-Schnittstelle (siehe „Gegner im Prototyp“).
- **Weitere Kandidaten:** Level-Generierung (liegt ebenfalls in der Mindestliste), Informed Individuals / Commander (Wunschliste), Spurfeld (unsortiert).
- **Frage an die Betreuer am 17.11.:** Reichen RL-gesteuerte Gegner als technischer Anker?

### Ziel, Verlieren & Fortschritt

Diese Punkte liegen inzwischen in der Mindestliste:

- **Ziel (Frederik, Leon):** Von A nach B, möglichst viele Schwarmmitglieder retten. Score = Zahl der Geretteten am Ende.
- **Neu:** Savezone = Checkpoint.
- **Aufbau:** Zusammenhängende Abschnitte ohne Ladescreens, getrennt durch Savezones. Dort ist man sicher, sammelt sich und zählt Überlebende.

Zur Wahl stehen vier Modelle:

| Modell | Von | Kern |
| --- | --- | --- |
| Mindestquote | Katharina | Mindestens ein Anteil des Schwarms (z. B. 50 %) muss die Savezone erreichen. |
| Verloren statt tot | Katharina | Mitglieder sterben nicht, sondern gehen verloren und sind in diesem oder einem anderen Level wiederzufinden. Ziel: alle finden. |
| Run | Jana | So weit wie möglich kommen. Reicht die Zahl der Überlebenden nicht für das nächste Level, zerfällt der Run. |
| Replay | Jana | Erreichte Levels erneut spielen und perfektionieren, mit Belohnung. |

- **Entschieden, vorerst (06.11.):** Möglichst viele Boids ins Ziel bringen.
- **Offen:** Was passiert, wenn alle Boids sterben? Welches der Modelle kommt später dazu?
- **Vorschlag für später:** „Verloren statt tot“ plus Mindestquote pro Abschnitt, Neustart am Checkpoint. Das passt zu „alle retten“ und zu den Savezones.

### Level-Struktur & Level-Generierung

- **Frederik:** Lieber Level-Generierung als KI-Gegner trainieren.
- **Jakob:** Tilemapping bzw. Wave Function Collapse für die Map-Generierung geht immer obendrauf.
- **Katharina:** Level aus Raumteilen, die verschieden zusammengesetzt werden. Variation über Farbe; Anzahl der Gegner und Schwarmgröße bleiben gleich.
- **Leon:** Handgemachte Rätsel- und Gegnersektionen, dazwischen per WFC generiert – erst, wenn der Kern trägt.
- **Offen:** WFC (kachelbasiert) oder Zusammensetzen vorgefertigter Raumteile?
- **Vorschlag:** Zuerst Raumteile zusammensetzen. Das ist einfacher, und handgemachte Rätsel bleiben kontrollierbar. WFC kann später die Übergänge füllen.
- **Offen:** Level-Generierung steht in der Mindestliste, gleichzeitig ist „erst später“ notiert. Gehört sie wirklich in die Demo am 09.02.? Da RL jetzt der Anker ist, wäre sie ein Kandidat für die Wunschliste.

## Wunschliste

Diese Punkte wollen wir und sie passen zum Konzept. Sie kommen dran, sobald die Mindestliste steht, spätestens in der Steam-Phase (Playtest durch andere Gruppen am 09.03., Release am 30.03.).

### Commander und Teilschwärme (Informed Individuals)

- **Idee:** Wenige Commander kennen die Richtung, der Rest folgt ihnen. Dadurch lässt sich der Schwarm sinnvoll aufteilen ([Couzin et al. 2005](https://www.nature.com/articles/nature03236)).
- **Teilschwärme:** Jeder Teilschwarm wird von einem Commander angeführt.
- **Savezone:** Commander und Gruppen können dort umsortiert werden.
- **Commander stirbt:** Seine Boids werden führungslos und müssen von einem anderen Schwarm gerettet werden. Folge: Chaos.
- **Couzin-Effekt:** Kleiner Winkel zwischen zwei Zielrichtungen ergibt einen Kompromiss, großer Winkel teilt den Schwarm oder er schnappt zu einer Seite ([Demo](https://www.complexity-explorables.org/)).
- **Umsetzungshinweis:** Jeder Boid bekommt ein Gewicht, wie stark er der Field-Richtung folgt. Commander haben ein hohes Gewicht, Mitläufer ein niedriges oder keins. Das löst auch das Problem „je näher, desto stärker“ aus dem Prototyp.
- **Offen:** Bekommen Commander ein eigenes Aussehen? Wie entsteht ein neuer Commander – durch Rettung oder durch das Mut-System?

### Wachstum und große Schwärme

- Versprengte einsammeln: Mehr Boids heißt mehr Leben, aber ein großer Schwarm passt nicht durch enge Passagen und muss sich aufteilen.
- Wachstum bis zu sehr großen Schwärmen (tausende Boids). Story-Hook: von einer Handvoll zu Tausenden.
- **GPU-Schwarm (10k+ Boids):** Simulation in einem Compute Shader (GLSL), gesteuert von GDScript. Etwa 100–300 „echte“ Individuen bleiben auf der CPU, die Masse der Mitläufer läuft auf der GPU. Rendering über `Texture2DRD` → MultiMesh, ohne Rückkopie zur CPU.
- **Einschränkung GPU:** Braucht den Forward+- oder Mobile-Renderer, kein Web-Export. Spielrelevante Daten (z. B. Zähler für gerettete Boids) nur in kleinen Puffern zurücklesen.
- **Demos:** [niceeffort](https://niceeffort.itch.io/boids-godot4-computeshader), [DevPoodle/godot-boids](https://github.com/DevPoodle/godot-boids/), [Godot Compute Texture Demo](https://godotengine.org/asset-library/asset/2764). Diese zielen auf Godot 4.1–4.2; kleine API-Anpassungen für 4.7 einplanen.

### Fog of War

- Sicht nur um den Schwarm herum. Der Rest wird zur Trace Map: Erkundete Wege bleiben als Spuren sichtbar und dienen als Karte.
- **Abhängigkeit:** Setzt das Spurfeld voraus (siehe Ideen zur Inspiration).

### Hindernisse

| Hindernis | Von | Wirkung |
| --- | --- | --- |
| Instabiles Gravitationsobjekt | Ariusha | Muss durch eine gewisse Zahl zurückgelassener Boids stabilisiert werden, um weiterzukommen. |
| Sprung aus dem Wasser | Frederik | Boids müssen oben aus dem Wasser springen. |
| Angelhaken | Jana | Betäubt Boids (Stun). |
| Sichtzone | Jana | Bereich, in dem der Sichtradius der Boids eingeschränkt ist. |
| Farbzone | Jana | Bereich, der Boids einfärbt und dadurch Gegner auf sie aufmerksam macht. |
| Bremszone | Jana | Bereich, in dem Boids langsamer werden. |
| Korallen, Steine, Haie | Katharina | Statische und bewegte Hindernisse unter Wasser. |
| Fallende Steine | Katharina | Werden vorher durch Staub angekündigt; bringt mehr „Fractured“ ins Spiel. |

Das Theme ist Unterwasser (06.11.), fast alle Ideen passen direkt. Sprünge aus dem Wasser funktionieren gut in der Seitenansicht.

### Items und Spezialfähigkeiten

| Item / Fähigkeit | Von | Wirkung |
| --- | --- | --- |
| Großer Fisch | Jana | Der Schwarm vereint sich kurz zu einem großen Fisch und kann dann nicht von Gegnern getötet werden (einschüchtern). |
| Speed | Jana | Kurzzeitig schneller. |
| Field-Upgrade | Jana | Mehr, stärkere oder länger wirkende Gravity Fields. Längere Fields könnten Balancing-Probleme machen. |
| Formen bilden | Ariusha | Boids formen aktiv oder per Power-Up eine Leiter oder Brücke, um ein Hindernis zu überwinden (wie Nanobots). |
| Käfig befreien | Ariusha | Gefangene Boids durch Attacken auf einen Käfig befreien. Setzt voraus, dass Boids angreifen können. |

## Ideen zur Inspiration

Hier steht alles, was interessant ist, aber noch nicht eingeordnet wurde. Diese Ideen sind ausdrücklich nicht verworfen – sie warten auf eine Entscheidung, spätestens nach dem Feedback im Dezember.

### Theme und Story

| Idee | Von | Kern |
| --- | --- | --- |
| Fischschwarm und Fischer | Frederik, Jakob | Der Fischschwarm soll von Fischern in Netze getrieben werden. Der Spieler ist nicht Teil der Welt, eher ein Management-Spiel mit freier Kamera und Gravity-Objekten oder Fischfutter mit Cooldown. |
| Kleiner Hai | Jakob | Ein kleiner Hai versucht, den großen Schwarm zu teilen, um einzelne Fische zu fressen – oder etwas Niedliches: er sucht einen Freund zum Spielen. |
| Umweltschutz | Jana | Fische vor der Umweltverschmutzung der Menschen schützen. Hindernisse: Fischernetze, Plastikflaschen, Angelhaken, Öllecks, Abwasserrohre. |
| Weltraum / Asteroid | Leon | Das Innere eines Asteroiden, dunkel; der leuchtende Schwarm im Glühwürmchen-Look ist die einzige Lichtquelle. Jakob: „Space-Theme geht eigentlich auch ganz gut.“ |
| Gottähnliche Rolle | Leon | Der Spieler greift nur über Schwerkraft ein. Das erklärt die indirekte Steuerung. |
| Junge, neugierige Boids | Ariusha | Boids sind am Anfang jung und neugierig, laufen herum und erkunden. Man muss sie zusammenhalten und beschützen. Später altern sie und halten besser zusammen. |
| Entspannter Ton | Ariusha | Eher Relax als Action, mit coolen Effekten und Musik. Steht im Widerspruch zu Jakobs „nichts allzu Entspannendes“. |

**Entschieden am 06.11.:** Unterwasser. Der Weltraum-Vorschlag ist damit vom Tisch; der leuchtende Schwarm als Lichtquelle passt aber auch zur Tiefsee. Beim Ton hat sich das Team für „eher fordernd“ entschieden.

### Steuerungs-Alternativen

Die Steuerung über Gravity Fields ist entschieden. Diese Varianten sind Inspiration für Level-Elemente oder Spezialfähigkeiten:

- **Kein Einfluss auf den Schwarm (Jakob):** Der Spieler beschützt oder jagt den Schwarm, treibt ihn vor sich her oder lockt ihn irgendwohin.
- **Qualle (Frederik):** Man steuert eine Qualle, die den Schwarm per Taste anzieht. Ein Balken läuft dabei ab; ist er leer, zerstreut sich der Schwarm.
- **Anführer steuern (Katharina):** Per Maus oder WASD einen Anführer steuern, dem der Schwarm folgt.
- **Passive Elemente (Frederik):** Schwarze Löcher oder Wasserströmungen lenken den Schwarm. Gut als feste Level-Elemente neben den Fields des Spielers.
- **Köder und Scouts (Leon):** Kleine Gruppen abkoppeln, um das Level zu erkunden oder Gegner in Fallen zu locken.

### Boid-Eigenschaften und Mut-System

- **Mut-System (Ariusha):** Mut als Währung für Spezialfähigkeiten, wie schon im ersten Prototyp.
- **Besondere Eigenschaften (Ariusha):** Einzelne Boids sind z. B. „flatterig“ oder „jung“ und bleiben nicht konstant beim Schwarm.
- **Individuelle Boids oder Boidgruppen (Jana):** Zum Beispiel durch Items. Liegt aktuell im Bereich „Bis 17.11.“.
- **Umsetzungshinweis:** Mut lässt sich als Gewicht umsetzen, wie stark ein Boid der Field-Richtung folgt. Mutige Boids führen, ängstliche folgen nur (Couzin-Prinzip).

### Spurfeld (Stigmergy)

- Boids hinterlassen leuchtende Spuren und folgen ihnen auch. Das Level „erinnert“ sich, wo der Schwarm war.
- Versprengte finden über die Spuren zurück. Gegner folgen ihnen ebenfalls – die Spur ist Nutzen und Risiko.
- **Technisch:** Boids schreiben Spuren in eine Grid-Textur, die verblasst und sich verteilt. Läuft fast kostenlos in derselben Compute-Pipeline wie ein GPU-Schwarm; für den Anfang reicht ein CPU-Grid von 128 × 128 Zellen.
- **Quelle:** [Jones 2010, Artificial Life](https://direct.mit.edu/artl/article-abstract/16/2/127/2650/Characteristics-of-Pattern-Formation-and-Evolution). Demos: [Sebastian Lague Slime Sim](https://github.com/SebLague/Slime-Simulation), [physarum-web](https://github.com/r-bit-rry/physarum-web).
- **Voraussetzung für:** Fog of War mit Trace Map, Gegner, die der Spur folgen.

### Intelligente Gegner und Reinforcement Learning

**Entschieden am 06.11.:** RL-gesteuerte Gegner sind vorerst der technische Anker. Die konkrete Planung steht im Abschnitt „Gegner im Prototyp“; hier bleibt der Hintergrund.

- **Idee (Ariusha, Jana):** Gegner folgen nicht stumpf, sondern umkreisen die Boids oder lauern ihnen auf. Jana schlägt Reinforcement Learning dafür vor; Frederik bevorzugt Level-Generierung statt KI-Training.
- **Training:** Mit [Godot RL Agents](https://github.com/edbeeching/godot_rl_agents). Das Training läuft in Python auf dem eigenen PC, das Spiel läuft dabei beschleunigt.
- **Im fertigen Spiel:** Entweder ONNX (braucht die .NET-Version des Godot-Editors) oder [Godot Native RL](https://godotengine.org/asset-library/asset/5358) (ohne C#, auch Web-Export; Community-Addon v0.4.0, früh testen).
- **Empfehlung:** Nicht jeden Boid als Agent trainieren. Besser ein KI-Commander für den Gegnerschwarm, der alle paar Sekunden Zusammenhalt, Aggressivität und Zielpunkt setzt. Zuerst handgeschrieben bauen, später durch eine trainierte Version ersetzen.
- **Lernen während des Spiels:** Deep-RL ist dafür zu datenhungrig. Machbar ist leichtgewichtiges Lernen wie [Dynamic Scripting](https://link.springer.com/article/10.1007/s10994-006-6205-6): Taktiken, die gegen den Spieler funktioniert haben, werden wahrscheinlicher. In Neverwinter Nights schlug ein so gesteuertes Team seine Gegner nach etwa 30 Begegnungen deutlich. Läuft komplett lokal.

### Weitere Ideen

- **Umgekehrtes Ziel (Jakob):** Statt zu retten versuchen, einen großen Schwarm zu „zerstören“ – würde zu „Fractured“ passen.
- **Endless-Modus (Jana):** So lange wie möglich gegen Gegner überleben.
- **SDF-Level (Leon):** Hindernisse in eine Distance-Field-Textur gebacken. Ausweichen ist dann ein Nachschlagen pro Boid statt einer Physik-Abfrage; zerstörbare Wände aktualisieren nur die Textur. Demos: [Red Blob Games Flow Fields](https://www.redblobgames.com/pathfinding/tower-defense/), [SDF Jump Flooding](https://www.shadertoy.com/view/ct2cDV).

## Offene Entscheidungen

Am 06.11. hat das Team die acht Grundsatzfragen für den Prototyp entschieden. Offen bleiben vor allem die Besetzung der Rollen, die Gegner-Schnittstelle und das Kürzen der Mindestliste.

### Entschieden am 06.11.

| Frage | Entscheidung |
| --- | --- |
| Theme | Unterwasser, Fischschwarm |
| Perspektive | 2D-Seitenansicht, keine natürliche Schwerkraft nach unten |
| Ziel | Möglichst viele Boids ins Ziel bringen (vorerst) |
| Gegner im Prototyp | Ja; der Minimalprototyp für den 17.11. kommt noch ohne Gegner aus |
| Technischer Anker | Reinforcement Learning für die Gegner (vorerst) |
| Ton | Eher fordernd |
| Code-Basis | Neues Godot-Projekt in GDScript |
| Rollen | Scrum Master, Art (2), Devs (2), RL (1) |

### Noch offen im Sprint bis 17.11.

- [ ] Rollen namentlich besetzen.
- [ ] Gegner-Schnittstelle zwischen RL und Devs abstimmen (Vorschlag im Abschnitt „Gegner im Prototyp“).
- [ ] Klären, welcher RL-Weg zum GDScript-Projekt passt: ONNX mit dem .NET-Editor oder Godot Native RL.
- [ ] Mindestliste auf 8–10 Notes kürzen. Kandidat zum Verschieben: Level-Generierung, da RL jetzt der Anker ist.
- [ ] Verlierbedingung festlegen: Was passiert, wenn alle Boids sterben?
- [ ] Spielform bestätigen: Singleplayer, PC mit Maus und Tastatur.

**Organisatorisch (Pflicht für den 17.11.):**

- [x] Rollen für den Sprint festgelegt: Scrum Master, Art, Devs, RL.
- [ ] GitHub-Board aufsetzen und die Prototyp-Tasks als Issues eintragen (Scrum Master).
- [ ] Devlog für den 16.11. schreiben (Scrum Master).
- [ ] Fragen an die Betreuer für den 17.11. sammeln, u. a.: Reichen RL-gesteuerte Gegner als technischer Anker?
- [ ] Später einplanen, wer Outreach übernimmt (Website, Trailer); Outreach zählt zur Betreuernote.
- [ ] Nächstes Meeting vor dem 16.11. vereinbaren.

### Später entscheiden

| Frage | Abschnitt | Spätestens |
| --- | --- | --- |
| Wie viele Fields gleichzeitig, mit Cooldown? Wird die Anziehung mit kürzerer Distanz stärker? | 1. Prototyp | Beim Bauen des Prototyps |
| Mausrad für Zoom oder für Field-Stärke? | 1. Prototyp, Mindestliste | Beim Bauen des Prototyps |
| Aufteilen: zwei Fields, abstoßendes Field oder Button? | 1. Prototyp | Nach dem ersten Spieltest |
| Können Boids angreifen oder nur fliehen? | Mindestliste | 01.12. (Blocking) |
| Folgen Gegner der Spur oder bewegen sie sich zufällig? | Mindestliste | 01.12. |
| Welche Gefahren und Hindernisse konkret? | Mindestliste | 01.12. (Theme steht fest) |
| WFC oder vorgefertigte Raumteile? Gehört Level-Generierung in die Demo? | Mindestliste | 01.12. |
| Spielform bestätigen (Singleplayer, PC, Maus und Tastatur) | Basis | 17.11. |
| Umfang: wie viele Abschnitte, wie lange ein Durchlauf? | Basis | 01.12. |
| Wie entsteht ein neuer Commander? | Wunschliste | Wenn Commander umgesetzt werden |

## Technik-Referenzen

| Thema | Quelle |
| --- | --- |
| Informed Individuals, Couzin-Effekt | [Couzin et al. 2005, Nature](https://www.nature.com/articles/nature03236) · [Complexity Explorables](https://www.complexity-explorables.org/) |
| Spurfeld / Physarum | [Jones 2010, Artificial Life](https://direct.mit.edu/artl/article-abstract/16/2/127/2650/Characteristics-of-Pattern-Formation-and-Evolution) · [Sebastian Lague Slime Sim](https://github.com/SebLague/Slime-Simulation) · [physarum-web](https://github.com/r-bit-rry/physarum-web) |
| GPU-Schwarm in Godot | [niceeffort](https://niceeffort.itch.io/boids-godot4-computeshader) · [DevPoodle/godot-boids](https://github.com/DevPoodle/godot-boids/) · [Godot Compute Texture Demo](https://godotengine.org/asset-library/asset/2764) |
| Flow Fields, SDF | [Red Blob Games Flow Fields](https://www.redblobgames.com/pathfinding/tower-defense/) · [SDF Jump Flooding (Shadertoy)](https://www.shadertoy.com/view/ct2cDV) |
| Reinforcement Learning in Godot | [Godot RL Agents](https://github.com/edbeeching/godot_rl_agents) · [Godot Native RL](https://godotengine.org/asset-library/asset/5358) |
| Lernende Spiel-KI | [Spronck et al. 2006, Dynamic Scripting](https://link.springer.com/article/10.1007/s10994-006-6205-6) |

## Glossar

| Begriff | Bedeutung |
| --- | --- |
| Boids | Schwarm-Algorithmus von Craig Reynolds: Jeder Boid folgt drei Regeln – Abstand halten (Separation), Richtung angleichen (Alignment), zusammenbleiben (Cohesion). |
| Gravity Field | Vom Spieler per Klick gesetztes, lokal wirkendes Feld, das Boids anzieht (oder abstößt) und nach einer Zeit verschwindet. |
| Commander / Informed Individual | Boid, der die Zielrichtung kennt. Wenige davon reichen, um einen ganzen Schwarm zu lenken. |
| Couzin-Effekt | Ziehen zwei Gruppen in verschiedene Richtungen, entsteht bei kleinem Winkel ein Kompromiss, bei großem eine Teilung. |
| Spurfeld / Stigmergy | Gitter, in das Boids Spuren schreiben, die verblassen; Boids und Gegner können ihnen folgen. |
| Trace Map | Karte aus den Spuren des Schwarms, sichtbar trotz Fog of War. |
| Savezone | Sicherer Bereich zwischen zwei Abschnitten, zugleich Checkpoint. |
| Spatial Grid | Gitter zur schnellen Nachbarsuche: Jeder Boid prüft nur die Boids in seiner und den benachbarten Zellen. |
| MultiMesh | Godot-Technik, viele gleiche Objekte mit einem einzigen Zeichenaufruf darzustellen. |
| WFC (Wave Function Collapse) | Verfahren, das aus Kacheln und Nachbarschaftsregeln Level generiert. |
| SDF (Signed Distance Field) | Textur, die für jeden Punkt den Abstand zum nächsten Hindernis speichert. |
| Dynamic Scripting | Lernverfahren für Spiel-KI, das erfolgreiche Taktiken während des Spiels wahrscheinlicher macht. |
