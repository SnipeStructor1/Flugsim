# Benchmark-Protokoll v1

## Gültigkeit

Ziel: Windows + RTX 5070 Desktop mit 12 GB. Tatsächliche CPU/RAM/GPU und Treiber
bei jedem Lauf erfassen. Cloud-Headless-Ergebnisse sind ausschließlich funktional.
Weder Software-Rendering noch eine andere GPU repräsentieren die Zielhardware.
Die Engine-Version muss exakt übereinstimmen, Assets und Quellen sind gehasht.
Vor dem Vergleich aktuelle offizielle Releases und Renderer-Voraussetzungen prüfen.

## Ablauf

1. Windows-Energieprofil, Treiber, Monitor, Hintergrundlast und Engine-Build notieren.
2. Mit identischer Szene, FOV 65° vertikal, Sichtweite 5000 m und Kamerapfad arbeiten.
3. Native 1920×1080, 2560×1440 und 3840×2160; Medium/High/Ultra, drei neue
   Prozesse pro Kombination. 30 s Warm-up, dann 60 s. Automatisch insgesamt 27 Läufe.
4. VSync, dynamische Auflösung und Frame Generation ausschalten. Upscaling vorerst
   ausschließlich native 1.0. Betriebssystem-Framelimiter ebenfalls kontrollieren.
5. Sichtbare Szene, tatsächliche Fenster-/Rendergröße und Profile auf Windows
   kontrollieren. Kein minimiertes Fenster; identische Sichtbedingungen.
6. Unveränderte JSON/CSV/Logs behalten. Vergleich erst nach visueller Paritätsprüfung.

Warm-up steht am Startpunkt; der Messflug beginnt danach. Bei gerenderten Läufen startet der Zeitgeber erst nach Szenenaufbau und
dem ersten `frame_post_draw`; Headless nach Szenenaufbau. Erster über die Warm-up-Grenze reichender Frame wird verworfen.
Der letzte über das Messende hinausreichende Frame wird nicht erfasst. Das Tool
verlangt mindestens 95 % der Sollzeit in verwertbaren Frameintervallen.
Profilreihenfolge ist deterministisch; für eine belastbare Studie zusätzliche
randomisierte/gekreuzte Reihenfolgen und thermisch stabile Bedingungen einsetzen.

## Messgrößen

`frametime_ms`: monotone Echtzeit zwischen zwei `_process`-Callbacks. Das ist ein
CPU-seitiges Main-Loop-Intervall einschließlich Wartezeiten und Render-Backpressure,
keine GPU-Zeit und keine bestätigte Bildschirm-Present-Zeit. Windows-Ergebnisse
später mit PresentMon/Engine-Profiler gegenprüfen; diese sind noch nicht integriert.

Durchschnitts-FPS = 1000 / arithmetisches Mittel aller Frameintervalle.
1%-Low = 1000 / Mittel der langsamsten `ceil(N×0.01)` Intervalle.
Median/P95/P99: linear interpolierte Quantile bei Index `(N−1)×p`.
Keine Mittelung von Momentan-FPS. Jede Wiederholung separat berichten.
Noch keine automatische Konfidenzintervall-/Cross-Run-Aggregation.

CSV: `frame,elapsed_s,frametime_ms`, Frames ab null, streng steigende Zeitstempel,
endliche positive Intervalle. Parser verwirft leere/unvollständige/inkonsistente Daten.
`summary.json` enthält Hardware, Source-/Manifesthash, Engine, Einstellungen, Logs,
Framestatistik und Telemetrie. `report.md` liefert die Ergebnistabelle.

Prozess-RSS und auf alle logischen CPUs normierte Prozess-CPU werden ungefähr
sekündlich gelesen. Das ist keine gesamte System-CPU-Auslastung.
NVIDIA-SMI liefert, falls vorhanden, Auslastung, belegten VRAM, Temperatur und
Treiber **pro Adapter**, nicht exklusiv pro Spielprozess. Alle Adapter bleiben in
der JSON erhalten; die tatsächlich verwendete GPU ist mit dem Engine-Log abzugleichen.
Nicht verfügbare Messwerte sind `null`. Telemetriezeit ist Zeit seit Prozessstart,
nicht exakt synchron zur Messphase; Startup/Warm-up anhand READY und Laufzeiten
unterscheiden. Eine genaue Phasenmarkierung für Telemetrie ist noch offen.

VRAM-Werte von NVIDIA-SMI sind MiB; Zielbudget von 10 GB vor Vergleich in dieselbe
Einheit umrechnen. Kein Bestehen des 60-FPS-/VRAM-Ziels allein anhand eines Mittelwerts.
P95-Ziel <16,7 ms, Streaming-Spitzen und Dauerlauf gesondert auswerten.

## Profilumfang und Grenzen

| Profil | Directional shadow atlas | SSAO | SSR | Volumetrischer Nebel | TAA |
| --- | --- | --- | --- | --- | --- |
| Medium | 2048 | aus | aus | aus | an |
| High | 4096 | an | an | an | an |
| Ultra | 8192 | an | an | an | an |

Gemessene Läufe benötigen Forward+. Funktionstests deaktivieren nicht verfügbare
Effekte und nutzen Dummy-Rendering; Profile im Headless-Test beweisen deren visuelle
Wirkung nicht. Kein Raytracing, DLSS, DLAA oder HDR-Monitorausgabepfad implementiert.
Die Szene verwendet PBR-Parameter und PhysicalSkyMaterial, aber keine hochwertigen
Textursätze, keine physikalische Wasser-/Wolkensimulation und kein Terrain-LOD.

## Separate Bildprüfung

`render_check.py` startet einen eigenen lokalen Xvfb-Prozess und beendet ihn danach.
Mesa llvmpipe rendert Forward+/Vulkan in nativen 1920×1080. Jeder Profilcheck
verarbeitet vier Frames, wartet auf `frame_post_draw` und speichert ein PNG.
Kein Warm-up-/Messzeitvertrag und keine FPS-Auswertung in diesem Modus. Große
Shader-Kompilierzeiten auf CPU-Rendering sind kein GPU-Performancewert.
Die Startkamera und Sonne bleiben für vergleichbare Bilder fest.

Software-CSV-Prüfungen sind nur mit `--software-validation` zugelassen. Erkannte
llvmpipe/lavapipe/softpipe-/Microsoft-Basic-Renderer im regulären Messmodus werden
als Fehler behandelt. Die separate JSON-Modus-/Statuskennzeichnung bleibt beim
Report erhalten. Das erfüllt den Messwerkzeugtest, nicht die Zielhardware-Baseline.
