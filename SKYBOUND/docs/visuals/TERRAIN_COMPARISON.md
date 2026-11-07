# Terrainvergleich – Szenenrevisionen 2 und 3

Gleiche Benchmark-Startkamera, Medium, 1920 × 1080, Godot 4.7.2 und Mesa
llvmpipe. Software-Rendering ist eine Bildprüfung, keine Performance-Messung.

- [Vorher, Revision 2](../../benchmarks/results/screenshots/Medium.png): flache,
  gleichförmige Hügel, große dunkle Wolkenschatten, wenig Materialvariation.
- [Nachher, Revision 3](terrain_revision3_medium.png): klar erkennbare Bergrücken,
  mehr Höhenvariation sowie auf Höhe und Neigung reagierende Oberflächen.
  Die unplausiblen Schatten der geometrischen Wolken sind ausgeschaltet.
- Zwischenbild mit übermäßig spitzen Bergen und schwebenden Objekten wurde
  untersucht; verringerte Rauschfrequenz und Netzinterpolation beheben die
  deutlichsten dieser Fehler.

Offene Bildfehler: vereinzelte gezackte Silhouetten durch das grobe Netz, einfache
Farben statt hochwertiger Textur-/Normalmaps, abstrakte Bäume/Gebäude/Wolken,
fehlende Uferdetails. Der See liegt in einer Senke, ist aber von dieser Kamera
durch das Gelände verdeckt. Zusätzliche Referenzkameras und kontrollierte
Nahansichten stehen noch aus. Die Bilder belegen keine RTX-5070-Leistung.

## Experimentelles Kachelterrain

[Streaming, 1080p Medium](terrain_streaming_revision3_medium.png): 64 geladene
Kacheln und drei Entfernungs-LODs; dieselbe feste Startansicht wie oben. Erste
Kachelbilder zeigten blaue Spalten. Gemeinsame interpolierte Randlinien und
beidseitige Skirts beseitigen die auffälligsten Spalten in dieser Ansicht.
Bildprüfungen anderer Kamerapositionen, schneller LOD-Wechsel und großer
Ladegrenzen stehen aus. Die grobe Randlinie verändert die Geometrie am
Kachelrand; sanfte LOD-Morphs fehlen. Keine Performance-Aussage.
