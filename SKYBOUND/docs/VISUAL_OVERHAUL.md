# Visual Overhaul – Bestandsaufnahme

Ausgangsbilder: `visuals/raptor_atmosphere.png` und
`visuals/infinite_terrain_far.png` (Godot 4.7.2, Software-Vulkan).

- Flugzeug: nur wenige Polygone, flache Flächen, sehr einfacher Cockpitersatz;
  Materialien, Rundungen und Einzelheiten reichen nicht an ein reales Flugzeug.
- Landschaft: prozedurale Farbvariation ohne gescannte PBR-Texturen; niedrige
  Geometrieauflösung und simple kegelförmige Bäume bleiben gut sichtbar.
- Himmel/Wasser: approximative Wolkenschicht und einfacher Wasser-Shader;
  keine validierte atmosphärische Streuung oder volumetrischen Wolken.
- Beleuchtung: helle Fernsicht, wenige glaubwürdige Nahdetails; die bisherige
  Softwareprüfung sagt nichts über die RTX-5070-Leistung aus.

## Asset-Recherche und Rechte

- Poly Haven: Die direkte Lizenz- und Assetseite `https://polyhaven.com/license`
  war am 2026-11-07 durch die Netzwerkpolicy nicht erreichbar (Proxy HTTP 403).
  Das erreichbare [offizielle Blender-Addon-Repository](https://github.com/Poly-Haven/polyhavenassets)
  ist kein Nachweis für die Lizenz einer konkreten heruntergeladenen Textur.
  Es wurde daher kein Material daraus übernommen.
- [FlightGear F-22](https://github.com/FGMEMBERS/F-22), Commit
  `da046fba441d9fb513b981905bcee80fd61e6706`: enthält ein detaillierteres Modell
  und eine GPL-v2-Lizenzdatei sowie Hinweise auf weitere Urheber. Für einzelne
  Meshes und Texturen sind Rechte und Weitergabepflichten nicht eindeutig genug
  zugeordnet; es wurden keine Dateien übernommen. GPL ist nicht CC0.
- ambientCG und Kenney wurden noch nicht für ein konkretes Asset verifiziert.
  Es werden keine Quellen oder Lizenzzusagen erfunden.

Nächster Schritt: eigenes reproduzierbares Blender-Modell mit einfacher
Materialtrennung als Basis; Qualitätskontrolle anhand gleicher Kameraansichten.
Die vollständige Direktive bleibt in Arbeit.

## Erstes eigenes Blender-Flugzeug

`tools/aircraft/build_raptor.py` erzeugt `flight/assets/raptor.glb` mit Blender
4.3.2 aus eigenem Code. Das Modell hat ein geschlossenes Rumpfnetz, separate
Flächen, Cockpitverglasung, Einläufe, Düsen und verschiedene Materialien.
Die beiden Querruder reagieren sichtbar auf Steuerbefehle. Godot liest GLB
direkt zur Laufzeit, ohne einen vorherigen Editorimport vorauszusetzen.

Bilder: `visuals/visual_jet_blender.png` und
`visuals/visual_cockpit_blender.png`, Ausgangsbild `visuals/raptor_atmosphere.png`.
Die Form und Düsen sind deutlicher als zuvor, aber Flügel, Leitwerk, Cockpit
und Landschaft wirken weiterhin schematisch; Fahrwerk und LOD fehlen. Dies ist
noch kein hochwertiges oder fotorealistisches Endergebnis. Der aktuelle Jet ist
eine eigenständige, unbewaffnete Annäherung, nicht vermessenes F-22-Modell.

Validierung: Flugmodell, Kameraund Kontrollflächen, 4,2-km-Überflug headless;
Bilder mit Software-Vulkan, kein Windows- oder GPU-Performance-Nachweis.

## Landschaftsmaterial – erster Schritt

Eine Fels-Albedo, Rauheits-, Höhen- und Normalkarte aus den offiziellen Godot
Demo Projects (MIT, konkrete Herkunft in `assets/licenses/README.md`) werden
im Flugmodus triplanar auf steile Flächen projiziert und mit prozeduralen
Gras-, Ufer- und Schneefarben gemischt. Die ursprüngliche Benchmarkmaterialdatei
bleibt erhalten. `visuals/visual_terrain_pbr.png` zeigt die neue Ansicht;
`visuals/raptor_atmosphere.png` dient als ältere Orientierung. Die Änderung ist
aus großer Flughöhe eher subtil; Nahdetail, Grastexturen, Baummodelle und
realistische Landschaft bleiben offen. Keine 1440p-/RTX-Performance gemessen.

## Licht und Tageszeit

Eine einfache 20-minütige Lichtschleife verändert Sonnenhöhe und -farbe; der
Sky-Shader färbt Horizont und Wolken bei tiefem Sonnenstand. Beispiel:
`visuals/visual_sunset.png`. Die Phase ist keine geografische/astronomische
Simulation und hat keine echte Nacht. Die Wolken bleiben zweidimensional;
das Bild wirkt wärmer, aber Terrain und Cockpit weiterhin stilisiert.

## Wasser

`visuals/visual_jet_lake.png` zeigt den Jet über dem See. Ein kleinskaliges
Muster variiert Wasserfarbe und Rauheit, ein dezenter Rand reagiert auf
Tiefendifferenz. Bestehende Wellen, Tiefenfarbe und Fresnel bleiben erhalten.
Die Aufnahme zeigt allerdings weiterhin eine relativ flache Wasserfläche und
steile künstliche Ufer; realistische Spiegelungen und Wellen sind nicht belegt.

## Grafikstufen und Referenzansichten

`SKYBOUND_GRAPHICS_PRESET`: Medium (2048 Schattenatlas, ohne SSAO/SSR/Nebel),
High (4096, SSAO/SSR/volumetrischer Nebel), Ultra (8192, dieselben Effekte),
Cinematic (Ultra plus 2500 m Schattenreichweite und Schattenfilter 1,4).
`SKYBOUND_RESOLUTION` unterstützt 1920×1080, 2560×1440 und 3840×2160.
Alle Stufen durchlaufen den Headless-Szenentest; Medium ist als Softwarebild
`visuals/visual_preset_medium.png` sichtbar. Keine Hardwaremessung. SSR auf
transparentem Wasser und 1440p/60 FPS sind nicht nachgewiesen.

Referenzen: Berg/Jet `visuals/visual_terrain_pbr.png`, Jet/See
`visuals/visual_jet_lake.png`, Cockpit `visuals/visual_cockpit_blender.png`,
Sonnenuntergang `visuals/visual_sunset.png`, Tiefflug
`visuals/visual_low_flight.png`. Einen Flughafen gibt es nicht; ein sechstes
Bild wäre irreführend. Der Tiefflug zeigt besonders deutlich, dass die
Baumkegel durch echte Vegetationsassets ersetzt werden müssen.

## Vegetation – erstes lizenziertes Modell

Die Kegelbäume der Flugansicht wurden durch ein instanziertes Modell von
Ricardo Sanchez ersetzt (CC BY 4.0, vollständiger Quell- und Urheberhinweis
in `assets/licenses/README.md`). Der Benchmark behält seine Referenzobjekte.
Vorher `visuals/visual_low_flight.png`, nachher
`visuals/visual_low_flight_trees.png`: Stamm und Blattkrone sind erkennbar.
Die Platzierung bleibt spärlich und gleichförmig; Artenvielfalt, realistische
Nadelbäume, Wind, LOD und Leistungsprüfung sind offen.

Eine 2560×1440-Tiefflugaufnahme in Medium wurde mit Software-Vulkan
erfolgreich erstellt: `visuals/visual_1440p_software.png`. Das beweist die
Ausgabeauflösung, aber weder Echtzeitfähigkeit noch RTX-Performance.

## Alpen-Anmutung und Lichtkorrektur

Auf Nutzerwunsch bleibt die Terrain-Generierung und Streaming-Planung unverändert.
Im Flugmodus: weniger volumetrischer und regulärer Nebel, ACES-Tonemapping,
angepasstes Umgebungslicht und Kontrast sowie weichere Übergänge zwischen
Schattenkaskaden. `visuals/alpine_light_before.png` und
`visuals/alpine_light_after.png` zeigen dieselbe Flugkamera nach 30
Simulationsschritten; zwischen den Aufnahmen wurde zusätzlich die Baumvariante
ersetzt. Die Gegenüberstellung ist daher kein isolierter Beleuchtungsbenchmark.

`visuals/alpine_ground_before.png` und `visuals/alpine_ground_after.png`
zeigen die gleiche bodennahe Kameraposition (Medium); beide Licht und Baumform
änderten sich zwischen den Aufnahmen. Die Szene nutzt eine MIT-lizenzierte
Grastextur sowie Felsmaterial und verbreiterte Schneezonen. Der alte
Höhenfilter, der überall unter 13 m Vegetation verhinderte, wurde auf den
bestehenden See beschränkt; Waldgruppen, Laubbäume und kleine Buschvarianten
folgen Höhe, Hang und zusammenhängendem Dichtefeld. Die Nadelbaum-Anmutung
basiert auf einer geformten Variante eines CC-BY-Laubbaums und ist kein
realistischer Nadelbaum-Scan; Büsche sind verkleinerte Baumvarianten.

Die Vegetationsprüfung kontrolliert deterministisches Neugenerieren, Höhe,
Hangneigung und Bodenkontakt für 1.483 Instanzen im Testgebiet. Die gleich
getesteten Flugfunktionen und 4,2-km-Reise funktionieren weiter. Softwarebilder
sind keine GPU-Leistungsmessung. Es fehlen echte Alpen-Nadelbäume, dedizierte
Sträucher und ein hochwertiges Erdmaterial; der Jet bleibt vorerst unverändert.

## Bodenmaterial-Vielfalt

Neben dem vorhandenen Gras und Fels wurden die zwei CC0-Materialien
ambientCG Ground037 (Waldboden) und Rock023 (Klippen) eingebunden. Jeweils
Albedo/Höhe und Normale/Rauheit sind in zwei 1024×1024-RGBA-Karten gepackt.
Das Flugmaterial mischt die vier unabhängigen Albedobilder anhand von
Geländeneigung, Höhenlage und weichen großräumigen Masken; gedrehte und
versetzte Abtastungen reduzieren Kachelwiederholung. Der Schnee ist weiterhin
prozedural. Die Normalkartenwirkung bleibt eine vereinfachte Näherung.

Gleiche Bodenansicht (Medium): `visuals/alpine_ground_after.png` vorher,
`visuals/terrain_detail_after.png` nachher; `visuals/terrain_detail_air.png`
zeigt einen Flugblick aus gleicher Position wie `visuals/alpine_light_after.png`.
Im Nahbild sind Äste und Blätter sichtbar. Die Texturdateien sind 1K, nicht
höher aufgelöst, und es gibt noch keine zehn unabhängigen Bodentexturen.
Flug-, Preset-, Vegetations- und X11-Eingabetests bestehen. Zusätzliche
Texturzugriffe und Speicherbedarf sind auf RTX 5070/Windows nicht gemessen.
Lizenzzuordnung steht in `assets/licenses/README.md`.
