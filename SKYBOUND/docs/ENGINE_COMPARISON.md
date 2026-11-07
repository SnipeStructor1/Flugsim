# Engine-Vergleich – offizieller Quellenstand 2026-11-07

Die offiziellen GitHub-`releases/latest`-Weiterleitungen nennen **Godot 4.7.2-stable**
[G1] und **O3DE 2605.0 / 26.05.0** [O1]. Godot 4.7.2 wurde projektlokal geladen,
mit offizieller SHA-512-Summe geprüft und ausgeführt. O3DE-Releasequellen wurden
selektiv gelesen, nicht gebaut. Die ursprüngliche Godot-4.6.3-Prüfung ist historisch.

Die öffentliche O3DE-Webdokumentation ist durch die Cloud-Netzwerkrichtlinie
nicht erreichbar (CONNECT 403). Geprüft wurden dieselben offiziellen Markdown-
Quellen aus `o3de/o3de.org`, Commit
`f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6`. Diese Dokumentation entwickelt sich
weiter; versionskritische Aussagen wurden mit Releasequellen 2605.0, Commit
`3db6943249d8bd7960b9ed7e9aee310b7668586e`, abgeglichen.
Godot-Dokumentation: Branch 4.7, Commit `9adca4c1c72917bfe1b7be3108abed5ce26696a6`.
Quellen und Inhaltsprüfsummen: [RESEARCH_SOURCES.json](RESEARCH_SOURCES.json).

## Fähigkeitsmatrix

D = direkt enthalten, P = separates Plugin, E = eigene Entwicklungs-/Integrationsarbeit,
N = im bezeichneten Standardpfad nicht verfügbar, U = nicht ausreichend bestätigt.
D bezeichnet dokumentierte Fähigkeit, keinen lokalen Leistungsnachweis.
Nicht vorhandener Beleg wird als U behandelt, nicht als N.

| Kriterium | Godot 4.7.2 | O3DE 26.05.0 |
| --- | --- | --- |
| Lizenz | MIT [G2]; Drittkomponenten getrennt | Apache-2.0 als Standard, alternativ MIT wählbar [O2]; Drittkomponenten getrennt |
| Pflichtkonto | Offizielles Binärpaket ohne Engine-Konto abgerufen | Öffentliche Releasequellen ohne Engine-Konto verfügbar; kein Cloud-Konto für lokalen Enginebetrieb erforderlich |
| Architektur | D: Forward+, Mobile, Compatibility; RenderingDevice-Abstraktion [G3] | D: Atom, RHI/RPI, datengetriebene Pässe und Feature Processors, clustered Forward+ [O3] |
| Vulkan / DirectX | D: Vulkan und D3D12 für Forward+/Mobile; Compatibility OpenGL [G3] | D: Vulkan und D3D12-RHI; D3D12 auf Windows [O4] |
| PBR / Schatten | D: Disney-PBR, Directional-/Omni-/Spot-Lichter und Schatten [G4] | D: PBR-Materialsystem, Directional-/Area-Lights und Schatten [O5] |
| SSAO / SSR / TAA | D in Forward+; Renderer-Matrix beachten [G3] | D: Ssao-, ReflectionScreenSpace- und Taa-Pässe in Release 2605.0 [O6]; TAA muss im Pipelinepfad aktiviert werden |
| Atmosphäre / Volumetrie | D: PhysicalSkyMaterial und volumetrischer Nebel; hochwertige dynamische Wolken E/P [G4] | D: Sky Atmosphere und Deferred Fog (Ray Marching); vollständiges Wolken-/Wettersystem E/P [O5] |
| Hardware-Raytracing | Kein fertiger Hardware-RT-Effekt durch die geprüfte Standard-Featureliste belegt; E/U. SDFGI ist kein Nachweis für Hardware-RT. API-/Treiber-RT-Unterstützung allein genügt nicht [G4] | D: RayTracingAccelerationStructure- und RayTracingPass, RT-Reflexionspass; diffuse Probe Grids verwenden Raytracing. Kein Beleg für universellen Pathtracer [O5/O6] |
| HDR | D: interner HDR-Renderpfad; Monitor-HDR ist gesondert zu prüfen [G3] | D: 16-Bit-HDR-Framebuffer und Display Mapper; tatsächliche Monitorausgabe gesondert prüfen [O5] |
| Upscaling | D: FSR1/FSR2; im SKYBOUND-Benchmark aus [G4] | D: Contrast Adaptive Sharpening dokumentiert; CAS ist allein kein temporales Upscaling. Konkreter FSR-/DLSS-Pfad U [O5] |
| Terrain / LOD | Kein nativer spezialisierter Terrain-Streamer in der geprüften Funktionsliste; P: Terrain3D-Kandidat, oder E [G4/P1] | D: Terrain Gem mit LOD/CLOD; Regionen dynamisch lad-/entladbar. Eigene Streaming-Policy und Datenquelle weiterhin E [O7] |
| Große Welten | D mit Sonderbuild `precision=double`, Editor/Exporttemplates und GDExtensions passend neu bauen; Origin Shifting alternativ E [G5] | Terrainregionen/Streaming sind Bausteine; planetare Double-Präzision oder fertiges Floating Origin nicht belegt, E/U. Kein direktes Pendant zum Godot-Double-Build behauptet |
| C++-Erweiterung | D: GDExtension / eigene Engine-Module [G4/P1] | D: C++-Gems, RPI/Feature Processors und Quellcode [O3] |
| Profiling | D: CPU-/GPU-Visual-Profiler, Tracy-/Perfetto-Anbindung [G4] | D: CPU-Profiling-/Profiler-Dokumentation und Atom-Werkzeuge [O8]; lokale Ausführung ungetestet |
| Build / Pflege | Verifiziertes Einzelbinärpaket ohne Systeminstallation; niedrigere Einstiegshürde | Asset Processor, Gems, Compiler und CMake; dokumentiert größerer Speicher-/Buildbedarf [O9] |

Explizite N-Fälle: Im Godot-Compatibility-Renderer sind unter anderem SSAO, SSR,
TAA und volumetrischer Nebel gemäß Renderer-Matrix nicht verfügbar [G3]. Ein
Fallback dorthin ist kein gleichwertiger High-/Ultra-Test. D3D12 ist kein
Linux-Renderbackend; dort wird für diese Projekte Vulkan benötigt [O4].

## Plugins und NVIDIA

Terrain3D ist ein **MIT-lizenzierter Drittanbieter-Kandidat**, kein Godot-Bestandteil.
Die Maintainer nennen C++/GDExtension, variable Regionen und bis zu zehn Terrain-LODs
[P1]. Das ist noch kein Nachweis einer funktionierenden Kombination mit 4.7.2 oder
planetarem Streaming. Kein Plugin wurde installiert.

Für **DLSS SR, DLAA, Ray Reconstruction, FG, MFG und Reflex** ist für keine der beiden
geprüften Standard-Engines eine fertige, versionspassende Integration belegt.
Derzeit Kategorie **E/U**, nicht D. Ein zukünftig verifiziertes Plugin könnte P sein.
Die separate SDK-Fähigkeit und ihre Bedingungen stehen in [NVIDIA_FEATURES.md](NVIDIA_FEATURES.md).
Keine NVIDIA-Punkte allein wegen C++, D3D12, Vulkan oder einer Blackwell-GPU.

## O3DE-Voraussetzungen und lokaler Blocker

Offizielle Mindestwerte [O9]: 16 GB RAM, passende D3D12-/Vulkan-GPU mit mindestens
2 GB VRAM, etwa 40 GB für vorgefertigte Installation oder **100+ GB** für Quellbuilds;
zusätzlich rund 2 GB RAM je Buildthread. Empfohlen werden 32 GB RAM.

Hier: Debian 13, fünf virtuelle CPUs, rund 33 GiB RAM, rund 60 GiB freier Speicher,
keine durchgereichte GPU, CMake/Ninja nicht im PATH. Ubuntu 24.04 LTS ist im gelesenen
Dokument die primäre Linux-Plattform. Die laufende Dokumentation empfiehlt CMake
3.30 und Clang 18; das konkrete 2605.0-`CMakeLists.txt` setzt noch 3.24 als Minimum.
Diese Unterschiede sind Versionsstände, keine Aufforderung, blind Systempakete zu ändern.

Ein kompletter Quellbuild würde das dokumentierte freie Speicherbudget überschreiten.
Das Ubuntu-Binärpaket wurde auf Debian ohne Hardware-GPU nicht als brauchbarer
Benchmark installiert. Selektiver Source-Checkout in `.tools/o3de-source` ist nur
Recherchematerial, keine Engineinstallation. O3DE-Benchmark: **NICHT GETESTET**.
Sinnvoller nächster Ort: Windows-Zielrechner mit passender GPU und genug SSD-Platz.

## Bewertung und Empfehlung

Gewichtung: Grafik 35 %, Performance 25 %, Erweiterbarkeit 15 %, geringer
Entwicklungsaufwand 10 %, NVIDIA-Integration 10 %, Wartbarkeit 5 %.
Score pro Kategorie 0–5, Gesamt = Summe(Gewicht × Score/5), maximal 100.
Offene Kategorien bleiben offen; kein Gesamtscore bei fehlender Grafik-/Performancemessung.

Die ersten 60 % folgen dem Hauptziel. Bildqualität anhand identischer Bilder,
Aliasing/Reflexionen/Schatten und volumetrischer Artefakte prüfen. Performance anhand
nativer Zielhardware-Frametimes, VRAM und Dauerlauf. C++-Adaptertests belegen
Erweiterbarkeit; protokollierte Einrichtung/Builds den Aufwand; tatsächlich lauffähige
Integration die NVIDIA-Kategorie; Release-/Pluginpflege die Wartbarkeit.

**Arbeitsentscheidung:** Godot als ausführbare erste Benchmarkbasis fortführen.
O3DE bleibt wegen belegter Atom-/RT-/Terrain-Bausteine ein ernsthafter Kandidat,
aber ohne äquivalente Szene und Zielhardware-Daten gibt es keinen Sieger.
Stride wird optional zurückgestellt: Ein dritter Adapter vor belastbarer Parität
würde den Testumfang erhöhen, ohne die offene Kernentscheidung zu lösen.

## Offizielle Belege

- [G1](https://github.com/godotengine/godot/releases/tag/4.7.2-stable): Release;
  [SHA512-SUMS](https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt).
- [G2](https://github.com/godotengine/godot/blob/4.7.2-stable/LICENSE.txt): MIT-Lizenz.
- [G3](https://github.com/godotengine/godot-docs/blob/9adca4c1c72917bfe1b7be3108abed5ce26696a6/tutorials/rendering/renderers.rst): Renderer-/Featurematrix.
- [G4](https://github.com/godotengine/godot-docs/blob/9adca4c1c72917bfe1b7be3108abed5ce26696a6/about/list_of_features.rst): PBR, Volumetrie, FSR, Profiling, GDExtension.
- [G5](https://github.com/godotengine/godot-docs/blob/9adca4c1c72917bfe1b7be3108abed5ce26696a6/tutorials/physics/large_world_coordinates.rst): Double-Build und Einschränkungen.
- [O1](https://github.com/o3de/o3de/releases/tag/2605.0): stabiles Release.
- [O2](https://github.com/o3de/o3de/blob/2605.0/LICENSE.txt): Apache-2.0 / optionale MIT-Lizenz.
- [O3](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/atom-guide/what-is-atom.md): Atom-Architektur.
- [O4](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/atom-guide/dev-guide/rhi/_index.md): RHI-Plattformen.
- [O5](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/atom-guide/features/_index.md): Renderfunktionen.
- [O6](https://github.com/o3de/o3de/tree/2605.0/Gems/Atom/Feature/Common/Assets/Passes): Release-Pässe.
- [O7](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/user-guide/visualization/environments/terrain/terrain-developer-guide/architecture.md): Terrainregionen;
  [LOD/CLOD](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/user-guide/components/reference/terrain/world-renderer.md).
- [O8](https://github.com/o3de/o3de.org/tree/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/user-guide/profiling): Profiling.
- [O9](https://github.com/o3de/o3de.org/blob/f3ffad05f5f4b5a86e1cbdc31ff64b80590deed6/content/docs/welcome-guide/requirements.md): Voraussetzungen;
  [2605.0 CMake](https://github.com/o3de/o3de/blob/2605.0/CMakeLists.txt).
- [P1](https://github.com/TokisanGames/Terrain3D): Maintainer-README; Drittquelle ausschließlich zur Pluginbewertung.
