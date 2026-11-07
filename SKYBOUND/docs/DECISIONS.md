# Priorisierte Aufgaben

| ID | Status | Aufgabe und Akzeptanzkriterien |
| --- | --- | --- |
| TERR-001 | ERLEDIGT | Deterministisches bergiges Terrain, nachvollziehbare Höhen-/Neigungsmaterialien, Tests und Vorher-/Nachher-Bild; alte Benchmarkrevision bewahren. |
| TERR-002 | IN ARBEIT – prozedurales Flugterrain mit 4,2-km-Test, weitere Skalierung offen | Experimenteller Szenenmodus mit drei LODs, Kachel- und Objektverwaltung sowie verbundenen Rändern vorhanden. Eine integrierte Headless-Szenenreise prüft Entladen, Rückladen, 1.250 m und 10.000 m sowie 222 Objekte. Die LOD-Wahl nutzt konservative 3D-Distanz, der Ladezustand horizontale Distanz. Eine feine Linie ist in Kachel- und monolithischer Bodenansicht sichtbar; Kantennormalen, Skirt- und Schattenabschaltung sind untersucht, die Ursache bleibt offen. Der Worker übernimmt jetzt die Rauschparameter als Snapshot. Als Nächstes bewegte Bilder und Objektzustand visuell prüfen, steile Übergänge, bildschirmfehlerbasiertes LOD und asynchronen Aufbau mit Zeit-/Speicherbudget untersuchen; Standardbenchmark bleibt monolithisch. |
| VIS-001 | IN ARBEIT | Sieben feste Kameras, reproduzierbare Softwarebilder und automatisierter Pixelvergleich vorhanden. Wald-, Sonnenuntergangs-, Wolken- und Wasseransichten benötigen echte Inhalte; Streaming-Ansichten und Hardwareabweichungen prüfen. |
| TERR-003 | OFFEN | Lizenzierte bzw. nachweisbar selbst erzeugte PBR-Texturen, Normalmaps und Variationsverfahren für Gelände; Nah-/Fernansicht prüfen. |
| ATM-001 | IN ARBEIT – Flugszene mit prozeduralem Himmel und 2D-Wolken; volumetrische Wolken und Tageszeit fehlen. | Tageszeit und skalierbare Wolken mit nachvollziehbaren Grenzen und Vergleichsbildern. |
| WATER-001 | IN ARBEIT – Flugszene mit animierter Oberfläche, Fresnel und Tiefenfärbung; Ufer und weitere Ansichten prüfen. | Wasser mit Wellen, Fresnel und Tiefenfärbung; Ufer- und Tiefenfälle prüfen. |
| ENV-001 | OFFEN | Vegetation mit Instancing, Wind und LOD; Lizenznachweise und Anzahl/Performance messen. |
| FLIGHT-001 | IN ARBEIT – spielbarer Flugprototyp, automatischer Überflug und Tastatureingabe S/C geprüft; F-22-inspirierte Form und einfacher Cockpitplatzhalter vorhanden; fotorealistisches Modell, Details, Start und Landung fehlen. | Sichtbares steuerbares 3D-Flugzeug und testbarer Flugphysikkern; spielbarer Flug mit Cockpit- und Verfolgerkamera. |
| SIM-001 | IN ARBEIT – grobe Jet-Parameter vorhanden; belastbare Quellen und realistische Kalibrierung fehlen. | Flugphysik schrittweise kalibrieren: Auftrieb, Widerstand, Schub, Gravitation, Strömungsabriss, Wind und Zeitschritttests. |
| PERF-001 | BLOCKIERT | Windows-/RTX-5070-Benchmarks: Zielhardware und Treiberzugang fehlen in der Cloud. |
| O3DE-001 | BLOCKIERT | Vergleichsszene und Messung auf geeigneter Plattform mit genügend Speicher/GPU. |

Die Reihenfolge wird anhand von Testergebnissen und sichtbaren Regressionen angepasst.

## Flugterrain ohne feste Kachelgrenze

Der Flugmodus aktiviert beim bestehenden Kachelmanager eine separate Planung
mit absoluten, auch negativen Kachelschlüsseln um das Flugzeug. Der vorhandene
Benchmark behält seine feste Kachelgrenze. Maximal 100 Kacheln bleiben resident;
zwei synchrone Aufbauten pro Physikschritt sind ein Mengen-, kein Zeitbudget.
Kollision tastet die aktuell gerenderte Kachel ab. Vegetation wird außerhalb
der ursprünglichen Szene deterministisch pro Kachel erzeugt und zusammen mit
ihr freigegeben. Vor der ersten Bewegung werden Kacheln vorgeladen. Fehlende
Kacheln können die Flugbewegung vorübergehend anhalten. Ohne Floating Origin
und Langzeittests ist unbegrenzte Präzision nicht nachgewiesen.

- Höchste Nutzerpriorität: prozedural nachladendes Flugterrain. Das Kachelgrid
  ist nicht mehr auf die alte Szene beschränkt, der Residentbestand bleibt
  begrenzt; Benchmarks behalten ihr bisheriges festes Raster. Ein 4,2-km-Flug
  ist geprüft. Floating Origin, längere Flüge und Performance bleiben offen.
