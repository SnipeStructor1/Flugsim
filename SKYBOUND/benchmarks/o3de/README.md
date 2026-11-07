# O3DE 26.05.0 – Voraussetzungen geprüft, Benchmark NICHT GETESTET

Offizielles stabiles Release: `2605.0`, Commit
`3db6943249d8bd7960b9ed7e9aee310b7668586e`. Selektiver Source-Checkout unter
`.tools/o3de-source` wurde zur Rendererprüfung gelesen. Das ist keine installierte
Engine; hier existiert kein ausführbarer O3DE-Szenenadapter.

Die [offiziellen Voraussetzungen](../../docs/ENGINE_COMPARISON.md) nennen
100+ GB freien Platz für den Quellbuild, 16 GB Mindest-RAM und eine geeignete
D3D12-/Vulkan-GPU. Hier: rund 60 GiB frei, Debian 13 statt primär unterstütztem
Ubuntu 24.04, keine durchgereichte GPU. Der Quellbuild passt nicht in das
angegebene Budget; ein vollständiger Download/Build wurde deshalb nicht begonnen.
Die Dokumentation nennt rund 40 GB für vorgefertigte Installationen, doch ein
Ubuntu-Paket ohne Hardware-GPU auf Debian würde keinen Zielbenchmark ermöglichen.

Nächste Umsetzung auf Windows-Zielhardware:

1. Compiler/Windows-SDK/CMake anhand des eingefrorenen 2605.0-Releases vorbereiten.
2. Projekt mit Atom/Terrain-Gems und Asset Processor erzeugen.
3. Gemeinsames `assets/shared/scene.json` übernehmen; Y-up/−Z-Kamera nach
   O3DE-Konventionen transformieren. Seed allein garantiert keine identische
   Zufallsfolge zwischen Engines; Geometrie-/Objektlisten müssen gemeinsam
   exportiert oder derselbe Generator ausdrücklich portiert werden.
4. Identische Kamera/Belichtung/Geometrie, Profil-Pässe und CSV-Vertrag implementieren.
5. Bildparität prüfen, drei Warm-up-/Messwiederholungen je Kombination durchführen.

Keine vermeintlich lauffähigen Projektdateien oder Platzhalter-Messergebnisse.
