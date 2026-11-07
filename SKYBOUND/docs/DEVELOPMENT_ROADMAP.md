# Entwicklungsplan mit Prüfkriterien

1. **Baseline (teilweise umgesetzt):** reproduzierbarer Godot-Szenenaufbau,
   Analyse-/Fehlerfälle, Headless-Matrix. Noch offen: Zielhardware-Bildprüfung. Offizielle Quellenprüfung für Godot 4.7.2 / O3DE 26.05
   und Software-Vulkan-Bildprüfung sind inzwischen erfolgt.
2. **Grafikbenchmark:** Windows-/RTX-5070-Inventar; drei Wiederholungen jeder
   Kombination; CSV/JSON, visuelle Prüfung, Present-Zeit-Gegenprobe und Dauerlauf.
3. **O3DE-Parität:** geprüfte Installation, Szenenadapter, gleiche Sichtbedingungen,
   dokumentierte Abweichungen und identische Auswertung. Erst dann Engineentscheidung.
4. **Produktionsgrafik:** lizenzierte PBR-Assets, Terrain-LOD, Kachelstreaming,
   Wasser-/Wolkensystem, Speicherbudgets. Neue Szenenversion und neue Baseline.
5. **Simulation:** C++-Kern, Einheiten-/Koordinatentests, deterministisches Input-Replay,
   Integrator-Konvergenz und Referenz-Aerodynamik. Noch kein vollständiger Simulator.
6. **Große Welt und optionale NVIDIA-Pfade:** Floating Origin/Streaming-Stresstests;
   SDK-/Pluginfreigabe, separate native-/Upscaling-/FG-Datensätze und Latenzprüfung.

Kein Zeitlimit aus Qualitätsgründen; jede Stufe endet mit überprüfbarem Nachweis,
nicht allein mit einer Featureliste.
