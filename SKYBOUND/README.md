# SKYBOUND

Rendering- und Benchmark-Grundlage für einen langfristigen Windows-Flugsimulator.
Kein vollständiger Flugsimulator und noch keine abgeschlossene Engine-Auswahl.

## Aktueller Stand

Godot 4.7.2 ist projektlokal mit offizieller SHA-512-Summe verifiziert. Prozedurale Szene, Kameraflug,
Profilkonfiguration und Analysewerkzeuge sind implementiert. **Forward+-Bildprüfung auf Software-Vulkan bestanden. RTX-5070-Benchmarks:
NICHT GETESTET.** Die Cloud hat keine durchgereichte GPU.
O3DE: nicht installiert; kein funktionsfähiger O3DE-Adapter vorhanden.
Die aktuellen stabilen Releases und Rendering-Funktionen sind anhand offizieller
Quellen geprüft; siehe `docs/ENGINE_COMPARISON.md`.

## Lokale Funktionsprüfung (Python 3.11+ / Godot 4.7.2)

Vom Verzeichnis `SKYBOUND`:

```sh
python scripts/validate.py
python benchmarks/tools/run.py --smoke
```

Der zweite Befehl führt 27 kurze Headless-Prüfungen aus: drei Profile × drei
Auflösungen × drei Wiederholungen. Er erzeugt **keine Performance-CSV**.
`--godot /voller/pfad/zur/engine` überschreibt die automatische Erkennung.
Der Runner benötigt ausschließlich die Python-Standardbibliothek. Projektlokales
Godot wird bevorzugt, `--godot` bleibt für explizite Pfade verfügbar.

## Windows-Grafikmessung (noch nicht auf Windows geprüft)

Godot und Python müssen bereits vorhanden sein. Der Benchmark-Runner lädt und installiert
keine Programme. Das optionale Linux-Bootstrap steht unten. PowerShell vom Verzeichnis `SKYBOUND`:

```powershell
.\scripts\Benchmark.ps1 -Godot 'C:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe'
```

Alternativ Python direkt:

```sh
python benchmarks/tools/run.py --godot /path/to/godot
```

Die Standardmatrix umfasst 27 Läufe mit jeweils 30 s Warm-up und 60 s Messung,
also mindestens 40,5 Minuten zuzüglich Starts. Forward+ und native Auflösung,
VSync und Frame Generation aus. Keine automatische Installation, keine SDKs.
Logs, Rohdaten, `summary.json` und `report.md` liegen in einem neuen Verzeichnis
unter `benchmarks/results/runs/`. Vorhandene Ausgaben werden nicht überschrieben.

Interaktive Szene: `godot --path benchmarks/godot --rendering-method forward_plus -- --interactive=true`.
Rechte Maustaste halten: Mausblick; WASD bewegen, Q/E ab-/aufsteigen; Escape beendet.
Ohne manuelle Steuerung läuft der gespeicherte Kamerapfad. Interaktive Läufe sind
nicht für die Messung vorgesehen.

Siehe [Ergebnisse](docs/BENCHMARK_RESULTS.md), [Protokoll](docs/BENCHMARK_PROTOCOL.md),
[Architektur](docs/ARCHITECTURE.md) und [nächste Schritte](docs/NEXT_STEPS.md).

## Reproduzierbare lokale Werkzeugvorbereitung (Linux x86_64)

```sh
python scripts/setup_tools.py
# Optional, nur Debian 13: keine Systeminstallation
python scripts/setup_tools.py --software-renderer
python scripts/render_check.py --output benchmarks/results/runs/meine-bildpruefung
```

Die Werkzeugversionen und vertrauenswürdig ermittelten Hashes stehen in
`scripts/toolchain.lock.json`. TLS-/Checksum-Prüfung bleibt aktiv. Die optionale
Bildprüfung nutzt Xvfb + Mesa llvmpipe und erstellt pro Profil vier gerenderte
Frames und ein 1920×1080-PNG. Das ist kein Performancebenchmark. Keine SDKs/Plugins
werden automatisch installiert. Die Bilder zeigen eine prozedurale technische
Basisszene und noch keine Produktionsgrafik.

Optional kann `render_check.py --pipeline-check --output benchmarks/results/runs/pipeline`
die echte CSV-Messkette auf dem CPU-Renderer prüfen (3 × 30 s Warm-up + 60 s Aufnahme).
Diese Ausgaben sind als `SOFTWARE_PIPELINE_VALIDATED_NOT_TARGET_HARDWARE` markiert
und sind keine RTX-5070-Ergebnisse. Software-Rendering im regulären Messmodus
wird abgewiesen; die Freigabe dafür erfolgt ausschließlich mit `--software-validation`.

## Experimentelles Kachelterrain

```sh
python scripts/render_check.py --terrain-stream --profiles Medium --output /tmp/skybound-stream-check
# Für schnellere Sichtprüfung mit 960×540 zusätzlich --preview verwenden.
```

Für interaktive Prüfung `godot --path benchmarks/godot --rendering-method
forward_plus -- --interactive=true --terrain-stream=true`. Der Modus ist für
Benchmarks gesperrt: sichtbare Übergänge, Ladeverhalten, CPU-/GPU-Leistung und
harte Speicherbudgets müssen noch überprüft werden.
