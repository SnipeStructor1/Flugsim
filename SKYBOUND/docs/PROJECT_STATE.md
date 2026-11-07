# SKYBOUND – Projektzustand

Stand: 2026-11-07. Wiederaufnahme: `AGENTS.md`, diese Datei, `NEXT_TASKS.md` und Git-Status lesen.

Die Benchmark-Basis wurde in Commit `2eb0373` gesichert und auf GitHub `main` veröffentlicht. Godot 4.7.2 ist projektlokal verfügbar; das Cloud-System hat keine RTX-GPU. Die Engine-/NVIDIA-Recherche und historische Ergebnisse stehen in `ENGINE_COMPARISON.md` und `BENCHMARK_RESULTS.md`.

## Aktuelle Arbeit: TERR-001

Die Revision 2 zeigte flache Hügel, geometrische Wolken und geringe Materialvariation. Revision 3 entwickelt ein deterministisches Rausch-/Bergkammmodell, eine See-Senke, stetige Normalen und einen prozeduralen Gelände-Shader mit Höhen-/Hangverteilung und triplanarer Rauschvariation. Sie ist ein technischer Schritt, kein fotorealistisches Terrain: Textur-Normalmaps, Erosion und Flüsse fehlen; Chunk-Streaming und Terrain-LOD sind nur experimentell vorhanden. Alte Benchmarkdaten beschreiben Revision 2 und sind mit Revision 3 nicht direkt vergleichbar.

441 Terrain-Stichproben auf endliche Werte, deterministische Seeds, Normalen, Höhenumfang und Seehöhe bestanden; Python-Benchmarktests und Headless-Smoke wurden ausgeführt. Die komplette Headless-Matrix (27/27), fünf Python-Tests, der Terrain-Test und die Medium-Bildprüfung mit llvmpipe sind bestanden. Das sichtbare Ergebnis und die Grenzen stehen in `visuals/TERRAIN_COMPARISON.md`.

## Blocker und Grenzen

Kein Hardware-GPU-Zugriff, Windows/RTX-5070-Performance ungetestet. O3DE-Quellbuild übersteigt den Cloud-Speicher. Flugphysik, echte volumetrische Wolken, Wasserphysik und vollständiges Streaming sind noch nicht implementiert. Bei nicht verfügbarem Godot markiert `scripts/validate.py` die Godot-Tests als übersprungen.

## Aktuelle Arbeit: TERR-002

Ein experimenteller Modus verbindet Kachelplanung, drei LOD-Stufen und die
Netzverwaltung mit der Szene. Er wird nur über `--terrain-stream=true` für
interaktive Nutzung, Headless-Smoketests oder Bildprüfungen aktiviert; echte
Benchmarkmessungen bleiben für diesen Modus gesperrt. Die ursprüngliche
monolithische Szene bleibt Standard.

Der Kachelplaner priorisiert Entfernung und begrenzt auf 64 Kacheln sowie zwei
Netzaufbauten pro normalem Frame (acht nur im Bildprüfmodus). Die Szene nutzt
für ihren begrenzten 2-km-Ausschnitt einen 3-km-Laderadius; auf dem kurzen
Benchmarkpfad bleiben dadurch alle 64 Kacheln geladen. Ein Headless-Kameraflug
hat 64 Kacheln erreicht; Entladen und fehlgeschlagene LOD-Ersetzungen sind im
isolierten Lifecycle-Test geprüft. Ein Sprung über den 3-km-Laderadius entlädt
16 Testkacheln; die Rückkehr lädt sie budgetiert wieder vollständig. Bodenobjekte werden den Kacheln zugeordnet,
nur bei geladenem Gelände angezeigt und auf das jeweilige Mesh interpoliert.

Erste 1080p-Bilder zeigten sichtbare Kachelrisse. Für alle LODs interpolieren
Kanten nun dieselbe grobe Randlinie; Skirts sind beidseitig. Die rechnerischen
Rand-/Mesh- und Objektpositionsprüfungen bestehen. Auf dem neuen 1080p-Bild
sind die auffälligen blauen Risse in der festen Startansicht weitgehend weg;
Nahtfreiheit bei Bewegung, steilen Kanten und allen Blickwinkeln ist noch nicht
nachgewiesen. Bild: `visuals/terrain_streaming_revision3_medium.png`.

Ein separater Befund: Das Setzen der Fenstergröße allein veränderte den internen
Renderpuffer nicht zuverlässig. Fenster und interner Puffer werden jetzt beide
auf die Vorgabe gesetzt; ein Lauf bricht bei Abweichung ab. Software-Bilder mit
960×540, 1920×1080, 2560×1440 und 3840×2160 bestätigten die tatsächliche
PNG-/Puffergröße. Dies sind keine GPU-Performancemessungen. Der frühere
Software-Benchmark verwendete 1080p und bleibt als Revision-2-Ergebnis erhalten.

Tests: sieben Python-Tests (davon zwei optional mit Pillow); Godot-Tests für Terrain, LOD, Kacheln, Planer und
Lifecycle und integrierte Szenenreise; Script-Vorprüfung; drei Standard-Headless-Läufe; Streaming-Headless-
Kamerafahrt und Bildprüfung. Einzelheiten in `visuals/streaming_validation.json`.

Offen: harter Zeit-/Byte-Budgetnachweis, asynchroner Aufbau, visuelle Bewegung über
die Ladegrenze in der Szene, morphende LOD-Wechsel, mehrere Referenzkameras, höherwertige
Material-/Normalmaps, Wasser, Wolken und Flugmodell. RTX-5070-/Windows-Tests
und O3DE bleiben mangels passender Hardware bzw. Speicher ungetestet.

Ein integrierter Headless-Szenentest prüft Laden → Sprung über 3 km → Rückkehr:
64 → 0 → 64 Kacheln und Sichtbarkeit/Position aller 222 Bodenobjekte bestehen.
Dies ersetzt keine visuelle oder zeitliche Prüfung des bewegten Bildes.

Nächster Schritt: schnelle Kamerabewegungen und Wechsel über Ladegrenzen samt
Sichtbarkeit/Objekten in der Szene visuell und zeitlich prüfen; dann asynchronen Aufbau
und harte Ressourcenbudgets untersuchen. `NEXT_TASKS.md` enthält die Reihenfolge.

## Aktuelle Arbeit: VIS-001

Sieben feste Blickpunkte liegen in `assets/shared/visual_views.json`;
`render_check.py --views ...` erzeugt Bilder und kann sie mit einem gespeicherten
Referenzordner vergleichen. `scripts/compare_images.py` misst RGB-Abweichungen
und liefert nur bei explizit gewählter Toleranz ein automatisches Fehlerurteil.
Die Bildvergleichstests verwenden Pillow, sofern vorhanden; fehlt es, werden sie
ausdrücklich übersprungen. Der Vergleich zweier 1080p-Bergbilder derselben Szene
zeigte bei Schwellwert 2 ein abweichendes Pixel; er beweist Reproduzierbarkeit
dieser Umgebung, keine allgemeine Grafikqualität. Sieben 960×540-Baselines liegen
unter `visuals/references/`, deren Screenshot-Manifest enthält die Hashes.
Die Einzelbefunde stehen in `visuals/VISUAL_VALIDATION.md`.

Sichtprüfung: Die Bergform und das Seebecken sind erkennbar. Der See ist weitgehend
gleichförmig und zeigt kaum Reflexionen; der Sonnenuntergang ist nicht überzeugend,
die Waldkamera zeigt nur vereinzelte Kegel und die Wolkenansicht geometrische
Scheiben. Dies sind offene Defizite, keine fertiggestellten Wald-, Wasser- oder
Atmosphärensysteme. Nahe Bodenansicht zeigt geringe Texturdetails. Die sieben
Ansichten dokumentieren den aktuellen Stand; Qualitätsverbesserungen und
Streaming-/Hardware-Regressionsprüfungen stehen noch aus.

Die sieben 960×540-Referenzbilder wurden anschließend erneut erzeugt und mit
expliziter mittlerer RGB-Toleranz 1/255 verglichen: 7/7 bestanden und in dieser
Software-Umgebung pixelgleich. Der optionale Pillow-Vergleich ist unabhängig
von Benchmark-FPS.

Die Ansichten `ground` und `high_altitude` wurden zusätzlich mit experimentellem
Kachelterrain erzeugt und gegen das monolithische Referenzbild verglichen. Die
Unterschiede umfassen erwartete LOD-Geometrie und Beleuchtung; sie sind kein
Qualitätsscore. Eine feine Linie ist bodennah sichtbar und erscheint auch im monolithischen
Referenzbild. Ein Lauf ohne Skirts unterschied sich vom Lauf mit Skirts um nur
zwei Pixel oberhalb Schwellwert 2; die Skirts wurden wieder aktiviert. Die Linie
ist damit nicht als Streaming-Fehler nachgewiesen; ihre Ursache bleibt offen. Bilder und Rohvergleiche: `visuals/streaming_references/`.
Die aktuelle LOD-Wahl berücksichtigt horizontale Entfernung, nicht Flughöhe.
