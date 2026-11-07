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

- TERR-002 wird zunächst getrennt vom produktiven Szenenpfad entwickelt.
  Gemeinsame Weltkoordinaten und Skirts sind eine Grundlage; sie ersetzen keine
  geprüfte Übergangsgeometrie, insbesondere an steilen Kanten. Hysterese verhindert
  Schwellenflattern, sagt aber nichts über Ladezeiten und Budgetierung aus.

- Die Kachelplanung ist eine reine Funktion des beobachteten Bestands. Eine
  fehlgeschlagene Mesh-Erzeugung darf keine Kachel als geladen markieren.
  Die Anzahl von Aufbauvorgängen wird begrenzt; harte Zeit- und Byte-Budgets
  werden erst nach Integration und Messung behauptet.

- Experimentelles Terrainstreaming bleibt explizit wählbar und von
  Performance-Messungen ausgeschlossen, bis Bild-/Bewegungs- und Budgettests
  abgeschlossen sind. Eine anfängliche Kantenlösung mit Skirts zeigte im
  1080p-Bild weiterhin Risse. Gemeinsame interpolierte Randlinien entfernten die
  auffälligen Risse in der geprüften festen Ansicht; allgemeine Nahtfreiheit
  ist damit nicht bewiesen.
- Fenstergröße und interner Renderpuffer werden separat gesetzt und nach dem
  ersten Bild verglichen. Die frühere Fenstereinstellung allein lieferte bei
  angeforderten 960×540 einen 1920×1080-Puffer. Durch Vorprüfung des
  Benchmark-GDScripts werden Parsefehler vor langen Bildläufen erkannt.

- Sieben feste Referenzansichten erfassen auch unvollständige Systeme sichtbar.
  Namen wie `forest` und `sunset` beschreiben die zu prüfende Absicht; sie
  bedeuten nicht, dass Wald oder Sonnenuntergang bereits produktionsreif sind.
- Pixelvergleiche benötigen übereinstimmende Auflösung und eine ausdrücklich
  gesetzte Fehlertoleranz. Ohne Schwelle protokollieren sie Unterschiede,
  entscheiden aber weder über Qualität noch über einen Regressionserfolg.

- Eine bodennahe Kachelansicht zeigte trotz verbundener Randpositionen eine
  helle Linie. Normalen an feinen Kanten werden nun aus groben Endpunkten
  interpoliert. Die Linie blieb im Vergleich sichtbar; Ursache und Abhilfe sind
  offen. Veränderte Pixel allein belegen weder Verbesserung noch Regression.
- Ursprünglich wurde LOD nur über horizontale Kacheldistanz gewählt; diese
  Entscheidung wurde durch konservative 3D-Distanz ersetzt (siehe unten).

- Ein gezielter Lauf ohne Skirts änderte an der Bodenansicht nur zwei Pixel über
  dem RGB-Schwellenwert 2; die fragliche Linie erschien auch im monolithischen
  Referenzbild. Die Skirts sind wieder eingeschaltet. Eine Streaming-spezifische
  Ursache für diese Linie ist daher nicht belegt.

- Experimentelles LOD berücksichtigt Flughöhe über den 3D-Abstand zu einem
  konservativen globalen Höhenintervall, einschließlich Skirts und Objektüberstand.
  Laden/Entladen bleibt horizontal, damit große Flughöhe Gelände nicht ausblendet.
  Die angenommene Schranke muss zur Höhenfunktion passen; bildschirmbezogene
  Fehlermetriken und tatsächliche Leistungswirkung sind weiterhin offen.
- Der experimentelle Kameramodus erweitert die Fernsicht bei großer Höhe. Der
  Boden-Nebel wird oberhalb 2.000 m als einfache Näherung reduziert, da der
  ursprüngliche konstante Nebel den 2-km-Ausschnitt in 10 km Höhe verdeckte.
  Dies ist weder ein physikalisch vollständiges Atmosphärenmodell noch eine
  globale Welt.
