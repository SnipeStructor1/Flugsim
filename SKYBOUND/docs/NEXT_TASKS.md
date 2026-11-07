# Priorisierte Aufgaben

| ID | Status | Aufgabe und Akzeptanzkriterien |
| --- | --- | --- |
| TERR-001 | ERLEDIGT | Deterministisches bergiges Terrain, nachvollziehbare Höhen-/Neigungsmaterialien, Tests und Vorher-/Nachher-Bild; alte Benchmarkrevision bewahren. |
| TERR-002 | IN ARBEIT | Experimenteller Szenenmodus mit drei LODs, Kachel- und Objektverwaltung sowie verbundenen Rändern vorhanden. Ein 3-km-Kamerasprung mit Entladen und Rückladen besteht im isolierten Test und als integrierte Headless-Szenenreise mit 222 Objekten. Eine feine Linie ist in Kachel- und monolithischer Bodenansicht sichtbar; Kantennormalen und Skirt-Abschaltung sind untersucht, die Ursache bleibt offen. Als Nächstes bewegte Bilder und Objektzustand visuell prüfen, steile Übergänge, höhenabhängiges LOD und asynchronen Aufbau mit Zeit-/Speicherbudget untersuchen; Standardbenchmark bleibt monolithisch. |
| VIS-001 | IN ARBEIT | Sieben feste Kameras, reproduzierbare Softwarebilder und automatisierter Pixelvergleich vorhanden. Wald-, Sonnenuntergangs-, Wolken- und Wasseransichten benötigen echte Inhalte; Streaming-Ansichten und Hardwareabweichungen prüfen. |
| TERR-003 | OFFEN | Lizenzierte bzw. nachweisbar selbst erzeugte PBR-Texturen, Normalmaps und Variationsverfahren für Gelände; Nah-/Fernansicht prüfen. |
| ATM-001 | OFFEN | Tageszeit und skalierbare Wolken mit nachvollziehbaren Grenzen und Vergleichsbildern. |
| WATER-001 | OFFEN | Wasser mit Wellen, Fresnel und Tiefenfärbung; Ufer- und Tiefenfälle prüfen. |
| ENV-001 | OFFEN | Vegetation mit Instancing, Wind und LOD; Lizenznachweise und Anzahl/Performance messen. |
| SIM-001 | OFFEN | Engine-unabhängiger Flugphysikkern mit festem Zeitschritt, Kräften und Tests. |
| PERF-001 | BLOCKIERT | Windows-/RTX-5070-Benchmarks: Zielhardware und Treiberzugang fehlen in der Cloud. |
| O3DE-001 | BLOCKIERT | Vergleichsszene und Messung auf geeigneter Plattform mit genügend Speicher/GPU. |

Die Reihenfolge wird anhand von Testergebnissen und sichtbaren Regressionen angepasst.
