# Buschmodelle und Herkunft

25 einzelne GLB-Dateien, ein Mesh pro Datei, Meter, +Y oben, Ursprung am Boden.
`catalog.json` enthält die tatsächliche Familienzuordnung und SHA-256-Hashes.

- `bush_00.glb`–`bush_04.glb`: fünf erzeugte Scrub-Oak-Büsche.
- `bush_05.glb`–`bush_09.glb`: fünf erzeugte Willow-Büsche.
- `bush_10.glb`–`bush_24.glb`: 15 eigenständig prozedural modellierte, dichte
  Wacholder-, Weiden- und Latschen-Annäherungen in je fünf Wuchsformen. Es sind
  keine botanisch validierten oder fotorealistischen Scans.

Die ersten zehn Modelle wurden mit
[JalapeñoSeed Groundcover Gift](https://github.com/jalapenoseed/groundcover-gift),
Commit `848a3416d6d347077d330443e6419578302b357e`, erzeugt. Copyright © 2026
Jalapeño Seed Productions; die MIT-Lizenz liegt als `JALAPENOSEED-MIT.txt` bei.
`JALAPENOSEED-ASSET-LICENSE.md` dokumentiert ausdrücklich, dass die Lizenz
auch für die erzeugten Assets dieser veröffentlichten Generatorfassung gilt.
Die Modelle enthalten die generierten Blatt- und Rindentexturen im GLB. Fünf
unabhängige Seeds pro Pflanzentyp erzeugen unterschiedliche Meshes, aber keine
zehn botanischen Arten.

Reproduzierbar: zuerst `blender -b --python tools/vegetation/bushes/build_bushes.py`,
dann `python tools/vegetation/bushes/build_external.py /pfad/zum/gepinnten/checkout`.
Das zweite Skript prüft den Upstream-Commit, erstellt temporär die fünf Seeds
8300–8304 (`scrub_oak`) und 8400–8404 (`willow_bush`), Dichte 1,25 und
Atlas-Zellgröße 256, und ersetzt ausschließlich `bush_00`–`bush_09`. Es schreibt
Katalog und Lizenzen erneut. Der Upstream-Generator und seine getrennten
Python-Abhängigkeiten werden nicht mitgeliefert; die GLBs sind direkt nutzbar.
Die anderen 15 stammen aus SKYBOUND-Generatorcode und verwenden keine externen
Texturen; die allgemeine SKYBOUND-Projektlizenz ist noch nicht festgelegt.
