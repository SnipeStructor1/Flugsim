# Technische Architektur

## Grenzen und Koordinaten

Simulation und Darstellung tauschen reine Daten aus. Der künftige C++20-Kern enthält
keine Engine-Header, Renderobjekte oder GPU-Abhängigkeiten. Die aktuelle Umsetzung
enthält bewusst noch keinen Aerodynamik-Solver. Python ist Werkzeugschicht,
GDScript nur Szenen-/Benchmarkadapter. Eine spätere C++-Anbindung benötigt Tests
für beide Adapter; sie ist noch nicht implementiert.

Weltkoordinaten: WGS84/ECEF in Double-Präzision für globale Positionen;
Luftfahrzeugphysik lokal in NED (North/East/Down), SI-Einheiten, Quaternionen.
Rendering erhält eine lokale Ursprungstransformation nach rechtsgängigem Y-up.
Kein direktes Kopieren von NED-Vektoren in Godot. Adapter müssen Position,
Orientierung, Geschwindigkeit und Ursprung gemeinsam transformieren.
Benchmark-Welt vorerst lokal Y-up in Metern, 2048 m Kantenlänge.

## Schnittstellenentwurf (noch keine API-Implementierung)

| Vertrag | Richtung | Pflichtdaten |
| --- | --- | --- |
| InputCommand | Eingabe → Simulation | Tick, Geräte-ID, normierte Achsen, Schalter |
| AircraftConfig | Konfiguration → Simulation | Version, Masse, Trägheit, Flächen, Tabellen, Einheiten |
| WeatherSample | Wetter → Simulation | Position, Zeitpunkt, Wind NED, Dichte, Druck, Temperatur |
| WorldState | Simulation → Adapter | Tick, Zeit, ECEF-Position, NED-Orientierung, Geschwindigkeit |
| TelemetryFrame | Simulation → Recorder | Tick, Kräfte, Momente, Sensoren, Fehlerstatus |
| MissionCommand/Event | Mission ↔ Simulation | Typ, ID, Tick, versionierte Nutzdaten |
| SaveSnapshot | Persistenz ↔ Simulation | Schema, Konfigurationshash, Zustand, RNG, Tick |

Der Kern nutzt feste Schritte von zunächst 120 Hz; die Rate bleibt konfigurierbar
und ist noch durch Stabilitäts-/Konvergenztests zu begründen. Renderinterpolation
zwischen zwei unveränderlichen Snapshots. Keine FPS-abhängigen Physikschritte.
Budgetüberschreitungen melden, Nachholschritte begrenzen und Rückstand protokollieren.
Input-Replay und versionierte Konfigurationen ermöglichen Regressionstests.
Bitweise Deterministik über Plattformen wird ohne Nachweis nicht versprochen.

## Subsysteme und Speicher

Aerodynamik, Integrator, Atmosphäre, Flugzeugkonfiguration, Eingaben, Telemetrie,
Missionen und Speicherstände erhalten eigene Module mit expliziten Abhängigkeiten.
Für globales Terrain sind asynchrones Streaming, Budgetierung und Cache-Eviction
noch zu implementieren; der experimentelle Kachelaufbau ist derzeit synchron. Ein Floating Origin gehört zum
Renderadapter und verändert keine absolute Simulationsposition.

Zielbudgets, keine Messwerte: 16,7 ms Gesamtframetime bei 60 Hz, maximal 10 GB VRAM
auf einer 12-GB-Karte. CPU/GPU-Budgets erst nach Profiling aufteilen; nicht einfach
addieren, da die Pipelines überlappen. Mindestens 30 Minuten Dauerlauf für
Speichertrends sowie gezielte Streaming-/Origin-Wechseltests vor Freigabe.

## Benchmark-Abhängigkeiten

`assets/shared/scene.json` definiert Seed, Terrainparameter, Profile, Auflösungen,
Kamerapositionen und Sonnenlicht. Godot erzeugt die Geometrie zur Laufzeit; keine
externen Assetimporte nötig. Der O3DE-Adapter fehlt noch. Daher besteht noch kein
Nachweis engineübergreifender Gleichheit. Kamera ist zeitbasierte stückweise lineare
Interpolation mit Blick auf einen festen Punkt; Ecken und Blickrotation sind
bewusst nicht geglättet und müssen in jedem Adapter gleich umgesetzt werden.

## Terrainrevision 3

`terrain_model.gd` verwendet deterministisches FastNoiseLite in Weltkoordinaten,
Bergmassiv-Gewichte und ein abgesenktes Seebecken. Zentraldifferenzen liefern
Normalen; `mesh_height` interpoliert dieselben Dreiecke wie das gerenderte Netz,
damit platzierte Objekte auf dem Netz stehen. Der Shader mischt prozedurale
Fels-, Gras-, Ufer- und Schneefarben anhand Höhe und Hang; triplanares Rauschen
ist Farbvariation, keine gescannten PBR-Texturen oder Normalmaps. Der Standard-Benchmark verwendet weiter ein einzelnes 2-km-Netz ohne Streaming/LOD. Nahtlose Kacheln und kontrollierte
LOD-Wechsel sind nächste Architekturaufgabe.

## Vorbereitete Kacheln und Detailstufen

`terrain_lod.gd` verwendet für den Ladezustand die horizontale Distanz zur
nächsten Kachel. Die Detailstufe verwendet zusätzlich eine konservative
3D-Distanz zum globalen Höhenintervall des Geländes. Drei LOD-Stufen und separate Lade-/Entladeschwellen besitzen 32 m
Hysterese, damit Grenzbewegungen nicht ständig neue Netze erzeugen.
`terrain_chunk_mesh.gd` berechnet aus derselben Höhenfunktion drei Rasterstufen
mit weltweit identischen gemeinsamen Stützpunkten und vertikalen Skirts.
Tests prüfen gemeinsame Randpunkte und interpolierte Kantennormalen. Bodennahe Bildprüfung zeigt eine feine Linie auch im monolithischen Bild; allgemeine Nahtfreiheit ist nicht belegt.
Die Standard-Benchmarkszene benutzt weiterhin das monolithische Netz. Ein
experimenteller Szenenmodus verbindet diese Bausteine mit einem Kachel-Lifecycle
und ordnet Bodenobjekte den geladenen Kacheln zu. Ressourcenfreigabe und
fehlgeschlagener LOD-Ersatz sind headless getestet; visuelle LOD-Übergänge und
Zeit-/Speicherbudgets benötigen weitere Prüfungen.

`terrain_stream_plan.gd` berechnet aus Kamera und tatsächlichem Bestand einen
reproduzierbar sortierten Plan. Zu entladende Kacheln stehen getrennt vor
Aufbauvorgängen; ein Höchstbestand und eine maximale Zahl von Aufbauten pro
Schritt begrenzen die geplante Arbeit. Der Planer verändert den Bestand nicht:
Aufrufer müssen Erfolg/Fehler beim Aufbau selbst behandeln und erst danach den
Zustand aktualisieren. Eine feste Anzahl Aufbauten begrenzt weder einzelne
Aufbauzeit noch Bytes; echte Zeit-/Speicherbudgets bleiben offen.

## Experimenteller Terrainmodus

`--terrain-stream=true` ist für `--interactive=true`, Headless-Smoke und
`--render-check=true` freigegeben; reguläre Performance-Messungen werden
abgewiesen. Der Szenenausschnitt besteht aus 256-m-Kacheln, bis zu drei
Detailstufen und bis zu 64 gleichzeitig vorhandenen Netzen. Die Oberflächen
benachbarter LODs benutzen an jeder Kante dieselbe lineare Randfunktion der
grobsten Stützpunkte; beidseitige Skirts dienen zusätzlich als Absicherung.
Ein `terrain_stream_manager.gd` erstellt und verwirft Netze nach Plan, erhält
bei fehlgeschlagenem Ersatz das alte Netz und aktualisiert den Bestand erst
nach erfolgreichem Aufbau. Bodenobjekte werden bei einer Bestandsänderung
ausgeblendet oder auf den aktuellen Dreiecken platziert.

Aufbau erfolgt derzeit synchron; ein Limit von zwei Netzen pro Frame ist kein
Zeitbudget. Maximal 64 Kacheln sind kein belegtes Byte-Budget. Der 3-km-Radius
umfasst den kurzen Benchmarkpfad; ein aussagekräftiger Entlade-/Nachladetest
benötigt größere Kamerabewegungen. Harte Frametimes, Ressourcenfreigabe im
Dauerlauf und visuelle Nahtfreiheit an steilen Übergängen sind noch offen.

## Visuelle Referenzen

`assets/shared/visual_views.json` definiert sieben feste Kamera-/Sonnenzustände.
Referenzansichten sind auf Bildprüfungen beschränkt und verändern den regulären
Kameraflug nicht. `render_check.py` speichert Szenen-/Kamerahashes und optionale
Vergleiche mit gleichnamigen Referenzbildern. `compare_images.py` berechnet
mittlere absolute RGB-Differenz und Anteil geänderter Pixel; Größenabweichungen
werden abgewiesen. Pillow wird nur für den Bildvergleich benötigt. Ein
Schwellwert muss bewusst gewählt werden, da Treiber und Renderer abweichen können.
Keine Bildkennzahl ist ein Urteil über Realismus oder Leistung.

Die Höhenabschätzung verwendet für die aktuelle Höhenfunktion das globale
Intervall −252 bis 698 m, erweitert um 32 m Skirt und 15 m Objektüberstand.
Daraus wird ein konservativer 3D-Abstand berechnet; die Ladeentscheidung bleibt
horizontal, damit das Gelände bei großem Höhenabstand nicht verschwindet. Das
Intervall muss bei Änderungen des Geländemodells oder größerer Objekte angepasst
werden. Projizierter Bildschirmfehler, Sichtbarkeit und GPU-Kosten werden noch
nicht berücksichtigt. Die experimentelle Kamera erweitert ihre Fernsicht und
verringert die konstante Nebeldichte oberhalb 2.000 m heuristisch; das ist kein
physikalisch vollständiges Atmosphärenmodell.

Die integrierte Diagnose `--smoke=true --terrain-stream=true
--stream-journey=true` setzt die Kamera in drei Phasen an Start, außerhalb des
Laderadius und zurück. Erst nach jedem stabilen Zustand prüft sie Kachelbestand
und Sichtbarkeit/Höhe der Bodenobjekte. Sie ist auf Headless-Smoke beschränkt
und endet nach Abschluss selbst; kein Zeit-/Performance-Benchmark.
