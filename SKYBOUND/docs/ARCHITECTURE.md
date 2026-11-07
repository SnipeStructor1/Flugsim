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
Streaming lädt Kacheln asynchron; Budgetierung, Hysterese und Cache-Eviction
müssen vor globalem Terrain implementiert werden. Ein Floating Origin gehört zum
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
ist Farbvariation, keine gescannten PBR-Texturen oder Normalmaps. Das Terrain ist
weiter ein einzelnes 2-km-Netz ohne Streaming/LOD. Nahtlose Kacheln und kontrollierte
LOD-Wechsel sind nächste Architekturaufgabe.
