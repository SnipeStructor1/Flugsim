# SKYBOUND – Projektzustand

Stand: 2026-11-07. Wiederaufnahme: `AGENTS.md`, diese Datei, `NEXT_TASKS.md` und Git-Status lesen.

Die Benchmark-Basis wurde in Commit `2eb0373` gesichert und auf GitHub `main` veröffentlicht. Godot 4.7.2 ist projektlokal verfügbar; das Cloud-System hat keine RTX-GPU. Die Engine-/NVIDIA-Recherche und historische Ergebnisse stehen in `ENGINE_COMPARISON.md` und `BENCHMARK_RESULTS.md`.

## Aktuelle Arbeit: TERR-001

Die Revision 2 zeigte flache Hügel, geometrische Wolken und geringe Materialvariation. Revision 3 entwickelt ein deterministisches Rausch-/Bergkammmodell, eine See-Senke, stetige Normalen und einen prozeduralen Gelände-Shader mit Höhen-/Hangverteilung und triplanarer Rauschvariation. Sie ist ein technischer Schritt, kein fotorealistisches Terrain: Textur-Normalmaps, Erosion, Flüsse, Chunk-Streaming und Terrain-LOD fehlen noch. Alte Benchmarkdaten beschreiben Revision 2 und sind mit Revision 3 nicht direkt vergleichbar.

441 Terrain-Stichproben auf endliche Werte, deterministische Seeds, Normalen, Höhenumfang und Seehöhe bestanden; Python-Benchmarktests und Headless-Smoke wurden ausgeführt. Die komplette Headless-Matrix (27/27), fünf Python-Tests, der Terrain-Test und die Medium-Bildprüfung mit llvmpipe sind bestanden. Das sichtbare Ergebnis und die Grenzen stehen in `visuals/TERRAIN_COMPARISON.md`.

## Blocker und Grenzen

Kein Hardware-GPU-Zugriff, Windows/RTX-5070-Performance ungetestet. O3DE-Quellbuild übersteigt den Cloud-Speicher. Flugphysik, echte volumetrische Wolken, Wasserphysik und vollständiges Streaming sind noch nicht implementiert. Bei nicht verfügbarem Godot markiert `scripts/validate.py` den Terrain-Test als übersprungen.

## Aktuelle Arbeit: TERR-002

`terrain_lod.gd` bietet drei Detailstufen, Lade-/Entladeschwellen mit Hysterese und Distanz zur Kachelbegrenzung; 20 Grenz-/Sprungfälle und drei Distanzfälle bestehen. `terrain_chunk_mesh.gd` erzeugt drei LOD-Meshes in Weltkoordinaten mit Skirts. Tests prüfen Dreieckszahlen, ungültige Eingaben und gemeinsame Randpunkte benachbarter Kacheln. Diese Bausteine sind noch nicht an die Szene angeschlossen; es gibt derzeit kein laufendes Streaming und keine validierte Nahtfreiheit. Die Medium-Bildprüfung zeigt weiterhin ausschließlich das monolithische Revision-3-Terrain.

Nächster Schritt: Kachel-Lebenszyklus mit begrenztem Arbeits-/Speicherbudget und zugeordneten Objekten anbinden. Unterschiedliche LOD-Ränder in steilem Gelände und schnelle Kamerabewegungen visuell prüfen, danach Referenzansichten ausbauen.
