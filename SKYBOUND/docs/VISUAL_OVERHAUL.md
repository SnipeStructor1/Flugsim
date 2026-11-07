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
