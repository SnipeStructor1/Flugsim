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

## Bodennah und aus großer Höhe

[Vorher, Boden](streaming_references/before_ground.png) ·
[Nachher, Boden](streaming_references/after_ground.png) ·
[Vorher, Höhe](streaming_references/before_high_altitude.png) ·
[Nachher, Höhe](streaming_references/after_high_altitude.png).

Die Nachherbilder verwenden angeglichene Kantennormalen. Die feine Linie in der
Bodenansicht ist auch im monolithischen Referenzbild sichtbar; ihre Ursache ist
nicht abschließend geklärt. [Ohne Skirts](streaming_references/without_skirts_ground.png)
ändert sich die Ansicht um nur zwei Pixel über RGB-Schwellenwert 2; Skirts bleiben
aktiv. Ein spezifischer Streaming-Riss ist für diese Linie nicht belegt. Der
Vergleich gegen das monolithische Referenzgelände zeigt zahlreiche erwartete
Pixelunterschiede durch LOD. Dies ist weder ein RTX-Performancewert noch ein
automatisches Qualitätsurteil. Rohdaten stehen in `streaming_references/comparison_runs.json`.

## Höhe und Sichtbarkeit

[Höhenabhängiges LOD bei 1.250 m](altitude/high_altitude.png): 12 Kacheln
in LOD 1, 52 in LOD 2, keine in LOD 0. Ein Vergleichsplan auf gleicher
horizontaler Position und niedriger Höhe ergab 12/10/42 für LOD 0/1/2.
Dies sind Geometriezählungen, kein Leistungsnachweis.

[10 km vor der Nebelkorrektur](altitude/extreme_before.png) ·
[10 km nach der Nebelkorrektur](altitude/extreme_after.png): Der geladene
2-km-Ausschnitt wird wieder sichtbar, zeigt aber deutlich seine quadratische
Grenze. Der Nebel ist eine Höhenheuristik; eine globale Landschaft und
physikalische Atmosphäre fehlen.
