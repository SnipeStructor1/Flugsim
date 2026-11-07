# Entscheidungen

- 2026-11-07: Bestehenden leeren Checkout verwenden; kein Worktree und keine
  Änderungen außerhalb des eigenen SKYBOUND-Projekts. Kein Commit/Push automatisch.
- Godot 4.6.3 vorhanden; zunächst Funktionsfähigkeit statt ungetesteter Enginebreite.
  Aktuell stabiler Release noch offiziell zu bestätigen.
- Python-Standardbibliothek für Portabilität und keine Paketinstallation.
  PowerShell ist nur der Windows-Einstieg; dieser Pfad hier nicht ausführbar.
- Prozedurale Materialien/Geometrie ohne externe Assets. Das ist eine technische
  Basisszene und noch kein Nachweis hochwertiger Produktionsgrafik.
- Gemeinsamer JSON-Vertrag und Quellhashes vor einem zweiten Adapter.
- Forward+ ist Pflicht für grafische Messung; Headless-Dummy ist nur Funktionsprüfung.
- NVIDIA-Funktionen und Upscaling bleiben aus, bis Integrations-/Lizenznachweise stehen.
- `BENCHMARK_RESULTS.md` und `NEXT_STEPS.md` liegen konsistent unter `docs/`.
- Externe Downloads/Abrufe und systemweite Installationen benötigen gemäß Auftrag
  vorherige Freigabe. Daher kein automatisches Nachinstallieren von O3DE/Tools.

- 2026-11-07, Fortsetzung: Downloadfreigabe erteilt. Godot auf verifiziertes
  4.7.2-stable festgelegt; O3DE-Release 2605.0 und offizielle Quelltexte geprüft.
- Keine O3DE-Vollinstallation auf dieser Cloud: Quellbuildbedarf 100+ GB gegenüber
  rund 60 GiB frei; keine Hardware-GPU und Debian statt primärer Ubuntu-Plattform.
- Portable Xvfb-/Mesa-Pakete aus signiertem Debian-Index und SHA-256-geprüften
  Artefakten, ausschließlich unter `.tools`; keine systemweiten Änderungen.
- Grafikprüfung entdeckt und korrigiert Terrain-Winding. Bildprüfung verwendet
  feste Framezahl statt der Benchmarkzeit und schreibt keine Performance-CSV.
- Die Wasserfläche liegt jetzt im Tal statt unsichtbar unter dem zentralen Hügel;
  gemeinsames Manifest `scene_revision=2` markiert diese Szenenänderung.

- 2026-11-07, Directive 002: Revision 3 erhält deterministische, weltkoordinatenbasierte
  Höhen- und Hangmaterialien. Ein anfängliches Modell führte zu nadelartigen Bergen;
  reduzierte Rauschfrequenz und geglättete Normalen verbessern das gerenderte Bild.
- Objekte werden auf der tatsächlich triangulierten Oberfläche positioniert. Der
  ursprüngliche Funktionswert allein verursachte Schweben zwischen Netzvertices.
- Die frühere benchmarkfähige Revision 2 bleibt in Git und in gespeicherten
  Ergebnissen erhalten. Gemessene Revision-2-Werte sind keine Revision-3-Messungen.
- Geometrische Wolken werfen vorerst keine Schatten: ihre großen dunklen Scheiben
  waren sichtbar unplausibel. Echtes Wolkenschattenmodell bleibt offen.
