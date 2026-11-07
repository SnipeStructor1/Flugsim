# SKYBOUND – Projektzustand

Stand: 2026-11-07. Wiederaufnahme: `AGENTS.md`, diese Datei, `NEXT_TASKS.md` und Git-Status lesen.

Die Benchmark-Basis wurde in Commit `2eb0373` gesichert und auf GitHub `main` veröffentlicht. Godot 4.7.2 ist projektlokal verfügbar; das Cloud-System hat keine RTX-GPU. Die Engine-/NVIDIA-Recherche und historische Ergebnisse stehen in `ENGINE_COMPARISON.md` und `BENCHMARK_RESULTS.md`.

## Aktueller Schwerpunkt: FLIGHT-001

Ein separat startbarer Flugprototyp nutzt die bestehende Landschaft unverändert.
Das selbst erzeugte Blender-Flugzeug ist an die F-22 angelehnt: gepfeilte Flächen,
zwei schräg stehende Leitwerke und zwei Auslässe. Ein einfacher Cockpitplatzhalter
ist vorhanden. Die Modellannahmen stehen in `F22_APPROXIMATION.md`.
Er bietet ein sichtbares Flugzeug, vereinfachte Kräfte und Steuerung, konstanten
Wind, Kollision mit Boden und Wasser sowie Verfolger- und Cockpitkamera. Ein
prozeduraler Himmel und ein animierter Wasser-Shader gelten nur in der Flugszene.
Ein automatischer Flug aus 700 m Höhe überquerte etwa 4.200 m in 1.447 Schritten; Modell- und
Szenentests sowie echte X11-Tasteneingaben für S und C bestanden. Bildprüfungen
verwenden Software-Vulkan und sind keine Hardware-Benchmarks.

Einschränkungen: Das Flugmodell ist nicht real kalibriert, Start/Landung fehlen,
das Cockpit ist nur ein Platzhalter, Wolken sind nicht volumetrisch und
Wasser ist eine visuelle Näherung. Maus, Gamepad und Windows sind nicht vollständig
geprüft. Das frühere 2-km-Limit wurde im Flugmodus durch prozedurales Streaming ersetzt. Der frühere Terrain-Freeze ist auf ausdrücklichen Nutzerwunsch aufgehoben;
die ältere feine Bodenlinie und fehlende RTX-Messungen bleiben offen.

## Historischer Stand: TERR-001

Die Revision 2 zeigte flache Hügel, geometrische Wolken und geringe Materialvariation. Revision 3 entwickelt ein deterministisches Rausch-/Bergkammmodell, eine See-Senke, stetige Normalen und einen prozeduralen Gelände-Shader mit Höhen-/Hangverteilung und triplanarer Rauschvariation. Sie ist ein technischer Schritt, kein fotorealistisches Terrain: Textur-Normalmaps, Erosion und Flüsse fehlen; Chunk-Streaming und Terrain-LOD sind nur experimentell vorhanden. Alte Benchmarkdaten beschreiben Revision 2 und sind mit Revision 3 nicht direkt vergleichbar.

441 Terrain-Stichproben auf endliche Werte, deterministische Seeds, Normalen, Höhenumfang und Seehöhe bestanden; Python-Benchmarktests und Headless-Smoke wurden ausgeführt. Die komplette Headless-Matrix (27/27), fünf Python-Tests, der Terrain-Test und die Medium-Bildprüfung mit llvmpipe sind bestanden. Das sichtbare Ergebnis und die Grenzen stehen in `visuals/TERRAIN_COMPARISON.md`.

## Blocker und Grenzen

Kein Hardware-GPU-Zugriff, Windows/RTX-5070-Performance ungetestet. O3DE-Quellbuild übersteigt den Cloud-Speicher. Real kalibrierte Flugphysik, echte volumetrische Wolken, Wasserphysik und vollständiges Streaming sind noch nicht implementiert. Bei nicht verfügbarem Godot markiert `scripts/validate.py` die Godot-Tests als übersprungen.

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

Ein integrierter Headless-Szenentest prüft Laden → Sprung über 3 km → 1.250 m →
10.000 m → Rückkehr: 64 → 0 → 64 → 64 → 64 Kacheln, passende Detailstufen
und Sichtbarkeit/Position aller 222 Bodenobjekte bestehen.
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
Die experimentelle LOD-Wahl berücksichtigt jetzt eine konservative 3D-Distanz
zum Höhenintervall. Kacheln werden weiterhin anhand horizontaler Entfernung
geladen, damit das Gelände unter einer Kamera in großer Höhe erhalten bleibt.
Bei 1.250 m ergab ein Software-Bild 0/12/52 Kacheln in LOD 0/1/2. Bei
10.000 m bleiben 64 Kacheln in LOD 2 mit 6.144 Geländedreiecken geladen.
Dies ist keine FPS- oder GPU-Leistungsbewertung.

Eine feste 5-km-Fernsicht und gleichförmiger Bodennebel verdeckten zuvor das
Gelände in 10 km Höhe. Der experimentelle Modus passt seine Fernsicht und den
Nebel heuristisch an die Flughöhe an. [Vorher](visuals/altitude/extreme_before.png)
und [nachher](visuals/altitude/extreme_after.png): Der kleine quadratische
2-km-Ausschnitt ist wieder erkennbar, eine globale Welt und physikalisch korrekte
Atmosphäre existieren aber weiterhin nicht. Die Nähe-/Höhen-/Extremhöhen- und
Rückkehrzustände bestehen im integrierten Headless-Szenentest.

## Historisch: Terrain-Freeze (inzwischen aufgehoben)

Ab sofort keine weitere Terrain-Entwicklung, LOD-Optimierungen, Kachelverwaltung,
Threading, Terrain-Streaming, Höhenalgorithmen oder neue Terrain-Tests ohne
ausdrückliche neue Freigabe. Der laufende asynchrone Test wurde abgeschlossen.
Der Schwerpunkt wechselt unmittelbar zum spielbaren Flugsimulator: sichtbares,
steuerbares Flugzeug, nachvollziehbare Flugphysik, Verfolger-/Cockpitkamera und
frühes Bild eines Flugzeugs. Himmel, Wolken, Beleuchtung und Wasser folgen.

Der experimentelle einzelne Worker berechnet nur Vertex-/Normaldaten; Mesh und
Scene Tree bleiben auf dem Hauptthread. Tests decken gleiches Datenresultat,
Worker-Wiederverwendung, veraltete Ergebnisse nach Kamerasprüngen, fehlerhaften
Mesh-Ersatz, Cleanup sowie vollständige synchrone und asynchrone Headless-Reisen
ab. Zwei 960×540-Ansichten mit synchroner und asynchroner Erzeugung bestehen
den Vergleich mit expliziter Toleranz 1/255; die mittleren RGB-Abweichungen
betragen etwa 0,257 und 0,296/255. Die Bilder sind nicht pixelgleich und
keine Performance-Messung. Daten: `visuals/async_streaming/`.

Bekannte Terrain-Einschränkungen bleiben bestehen: nur 2 km Ausschnitt,
experimentelles LOD/Streaming, offene allgemeine feine Darstellungslinie,
keine nachgewiesenen harten Zeit-/Byte-Budgets oder RTX-5070-Messungen.
Diese frühere Pause wurde inzwischen ausdrücklich aufgehoben.

## Aktuelle Fortsetzung: Terrain und Flugdynamik

Der asynchrone Terrain-Worker übernimmt nun sämtliche Rauschparameter als
Wertesnapshot und erzeugt eine eigene Kopie. Änderungen der Konfiguration
während ein Manager Kacheln besitzt werden erkannt und abgewiesen. Ein Test
prüft identische Worker-/Hauptthreadgeometrie mit geänderten Parametern; die
Terrain-, Lifecycle- und synchronen/asynchronen Szenenreise-Tests bestanden.
Die Bodenlinie bleibt auch bei abgeschalteten Schatten sichtbar; ihre Ursache
ist weiterhin ungeklärt.

Das Flugmodell berücksichtigt eine einfache höhenabhängige Standardatmosphäre,
Schubverzögerung und geschwindigkeitsabhängige Steuerautorität. Die Anzeige
zeigt näherungsweise IAS. Tests für Atmosphäre und Schub sowie Modell-,
Überflug- und X11-Tastaturtest bestanden. Dies ist keine validierte F-22-Simulation.

## Prozedurales Flugterrain

Der Flugmodus verwendet ein unbeschränktes Kachelkoordinatengitter mit
maximal 100 geladenen Kacheln, distanzabhängigem LOD, Entladen hinter dem
Flugzeug und Höhenabfrage der aktuell gerenderten Kachel. Ein Flug von 4,2 km
und Planertests für negative Koordinaten und Rückkehr bestanden. Außerhalb des
ursprünglichen Bereichs entstehen einfache deterministische Bäume pro Kachel.
Ein Bild 5 km südlich des Ursprungs: `visuals/infinite_terrain_far.png`.

Praktische Grenzen: Kein Floating Origin; sehr große Koordinaten verlieren
Genauigkeit. Die Welt ist nicht global oder auf realen Geodaten aufgebaut,
Vegetation und Formen sind einfach. Kacheln werden im Flugmodus synchron
erzeugt, was zu Rucklern führen kann; falls die nächste Kachel noch fehlt,
pausiert die Flugbewegung bis sie geladen ist. Eine Langzeit-/Hardwareprüfung
und visuelle Übergangsprüfung fehlen. Das Flugzeug bleibt ein prozeduraler,
nicht fotorealistischer Platzhalter.

## Visuelle Überarbeitung – in Arbeit

Bestandsaufnahme und Quellenprüfung: `VISUAL_OVERHAUL.md`. Eigenes Blender-GLB
mit separaten Materialien, Düsen und beweglichen Steuerflächen ersetzt den
vorigen prozeduralen Flugzeugrumpf. Das Cockpit ist weiterhin ein Platzhalter.
Bilder und Flugtests sind dokumentiert; PBR-Assets, echte Beleuchtungsqualität,
Wasser, Vegetation, Presets und hochwertige Flugzeugdetails bleiben offen.
