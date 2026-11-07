# Benchmark-Ergebnisse – 2026-11-07

**Historische Szenenrevision 2.** Das aktuelle Terrain ist Revision 3; diese
Ergebnisse sind nicht ohne neue Messung übertragbar.

## Nachgewiesener Stand

Godot **4.7.2.stable.official.ed1daf0bf**, offizielles Linux-Paket projektlokal,
SHA-512 gegen die veröffentlichte Summe geprüft. Die Cloud hat fünf virtuelle
Xeon-Platinum-8573C-CPUs und rund 33 GiB RAM, keine durchgereichte RTX-/Hardware-GPU.
Sie ist nicht der Windows-Zielrechner.

| Prüfung | Ergebnis |
| --- | --- |
| Headless: 3 Profile × 3 Auflösungen × 3 Wiederholungen | 27/27 bestanden |
| CSV-Analyse und fehlerhafte Reportdaten | 5/5 Tests bestanden |
| Ungültige Engine-Aufrufe / Moduskonflikte | 4/4 Fehlerfälle korrekt abgewiesen |
| Forward+/Vulkan: Medium, High, Ultra auf llvmpipe | 3/3 Bildprüfungen bestanden |
| Echte CSV-Aufnahme: Medium / 1920×1080, je 30 s Warm-up + 60 s Aufnahme | 3/3 bestanden, ausschließlich Software-Renderer |

Der Headless-Test nutzt kurze 0,1-s-/0,5-s-Zeiten und erzeugt keine Performance-CSV.
Die separate Bildprüfung verarbeitet pro Profil vier Frames, erzeugt echte
1920×1080-PNGs und wurde visuell kontrolliert. Dabei wurde falsches Terrain-Winding
korrigiert. Die Wasserfläche wurde aus dem zentralen Hügel ins Tal versetzt
(`scene_revision=2`). Die Landschaft, Wasserfläche, Vegetation, Gebäude, Material-
Testobjekte und Schatten sind sichtbar. Wolken sind geometrische Platzhalter.
Das ist eine funktionale Basisszene, kein Nachweis von Produktionsgrafikqualität.

Bilder: [Medium](../benchmarks/results/screenshots/Medium.png),
[High](../benchmarks/results/screenshots/High.png),
[Ultra](../benchmarks/results/screenshots/Ultra.png).

## Messkette mit echten Software-Renderer-Daten geprüft

**Keine RTX-5070-Performancewerte.** Vulkan-Gerät: Mesa llvmpipe 25.0.7 / LLVM 19.1.7,
CPU-Rendering. Die folgenden Daten prüfen Aufnahme, Zeitstempel, Auswertung,
Prozessmetriken und Berichterstellung. Native Auflösung, kein Upscaling, keine FG.

| Wiederholung | CSV-Frameintervalle | Verwertbare Aufnahmezeit | Prüfung |
| --- | --- | --- | --- |
| 1 | 79 | 59.249 s | bestanden |
| 2 | 79 | 59.936 s | bestanden |
| 3 | 87 | 59.430 s | bestanden |

Jede Statistik wurde aus den gespeicherten Rohdaten erneut berechnet und gegen
`summary.json` geprüft. Alle drei Aufnahmen erfüllen die Mindestabdeckung von
95 % der 60 Sekunden. Nullwerte für NVIDIA-Auslastung, VRAM und Temperatur sind
hier erwartbar; Prozess-RSS und normierte Prozess-CPU werden erfasst.

Die Software-Framestatistiken liegen nur im ausdrücklich gekennzeichneten
[Software-Bericht](../benchmarks/results/software_validation/report.md).
[JSON](../benchmarks/results/software_validation/summary.json) enthält Hardware,
Einstellungen, Einzelstatistiken und Telemetrie. Drei CSVs und Lauf-Logs liegen
im selben Verzeichnis. Diese Ergebnisse gehen **nicht** in eine Enginebewertung ein.

Weitere Nachweise: `benchmarks/results/validation.json`, `render_validation.json`
und `error_checks.json`. Godot-Quell-/Szenenhashes wurden gegen den finalen Stand
geprüft. Keine systemweiten Programme, NVIDIA-SDKs oder Plugins installiert.

## Noch nicht geprüft

| Gegenstand | Status |
| --- | --- |
| Windows / RTX 5070, 1080p/1440p/4K | NICHT GETESTET |
| 60-FPS-/P95-/10-GB-VRAM-Ziele auf Zielhardware | NICHT GETESTET |
| Windows-Prozessmetriken / NVIDIA-Telemetrie / PowerShell-Starter | NICHT GETESTET |
| Präsentationszeit-Gegenprobe / mindestens 30 Minuten Dauerlauf | NICHT GETESTET |
| O3DE Installation / äquivalente Szene / Grafikmessung | NICHT GETESTET |
| DLSS / DLAA / RR / FG / MFG / Reflex | NICHT GETESTET |
| Optional Stride | NICHT GETESTET |

O3DE 26.05.0 wurde anhand offizieller Quellen und Release-Pässe untersucht, aber
nicht installiert. Der dokumentierte Quellbuildbedarf von 100+ GB übersteigt
rund 60 GiB freien Cloud-Speicher. Die Cloud hat keine Hardware-GPU und verwendet
Debian statt der primären Ubuntu-Plattform. Ein vorgefertigtes Ubuntu-Paket auf
dieser Konfiguration wurde nicht als sinnvoller Zielbenchmark installiert.

Es gibt keinen belegten Engine-Sieger und keine erfüllte RTX-60-FPS-Zusage.
Bewertungsgewichte stehen in `ENGINE_COMPARISON.md`; offene Kategorien bleiben
unbewertet. Verbleibende Arbeit: `NEXT_STEPS.md`.
