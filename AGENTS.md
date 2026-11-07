# SKYBOUND – Regeln für Entwicklungsagenten

- Arbeite im vorhandenen Checkout und lies vor jedem Arbeitsabschnitt `SKYBOUND/docs/PROJECT_STATE.md`, `NEXT_TASKS.md` und den Git-Status.
- Erhalte bestehende Änderungen; keine Worktrees, Resets oder Remote-Pushes ohne ausdrücklichen Auftrag.
- Projektstamm: `SKYBOUND/`. Python 3.11+, Godot 4.7.2; projektlokale Werkzeuge unter `.tools` sind ignoriert. `python3 scripts/setup_tools.py --software-renderer` bereitet sie unter Debian 13 vor.
- `python3 scripts/validate.py` führt Python-Tests und, falls Godot vorhanden ist, die deterministischen Terrain-, LOD-, Kachel-, Planungs- und Lifecycle-Tests, die integrierte Streaming-Szenenreise sowie eine Script-Vorprüfung aus. Fehlendes Godot wird als übersprungen ausgewiesen.
- `python3 benchmarks/tools/run.py --smoke --profiles High --resolutions 1920x1080` prüft den Benchmark-Ablauf; keine GPU-Messung.
- `python3 scripts/render_check.py --profiles Medium --output /tmp/skybound-render-<eindeutig>` rendert ein Bild mit Software-Vulkan. Die Ausgabe ist keine RTX-Messung.
- Nach einem Arbeitspaket Tests, Bildprüfung (bei Grafikänderungen), `PROJECT_STATE.md`, `NEXT_TASKS.md` und gegebenenfalls `DECISIONS.md` aktualisieren; abgeschlossene Meilensteine sauber committen.
- Keine erfundenen Messwerte, keine ungeprüften NVIDIA-Integrationen. Windows-/RTX-5070-Ergebnisse nur auf der tatsächlichen Hardware als solche ausweisen.
- `assets/shared/scene.json` trägt eine Szenenrevision. Änderungen an Geometrie, Kameras oder Materialien machen alte Benchmarkwerte nicht vergleichbar; historische Ergebnisse erhalten und getrennt ausweisen.

- **Terrain-Freeze (Nutzeranweisung):** Keine weitere Terrain-Entwicklung,
  LOD-Optimierung, Kachelverwaltung, Threading, Terrain-Streaming,
  Höhenalgorithmen oder neue Terrain-Tests ohne ausdrückliche neue Freigabe.
  Bekannte Einschränkungen dokumentieren. Aktueller Schwerpunkt: spielbarer
  Flugsimulator mit Flugzeug, Flugmodell und Cockpit-/Verfolgerkamera.
