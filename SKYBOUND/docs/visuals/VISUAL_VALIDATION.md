# Visuelle Referenzen und aktueller Befund

Alle Bilder wurden mit Godot 4.7.2, Forward+, Medium und Mesa llvmpipe bei
960×540 erzeugt. Sie sind funktionale Referenzen, keine Messung der RTX 5070.
Das Manifest in `references/manifest.json` enthält Szenen-, Kameradaten- und
Bildhashes. Regressionsläufe werden separat protokolliert; ein Pixelunterschied
allein bewertet keine Grafikqualität.

| Ansicht | Referenz | Beobachtung |
| --- | --- | --- |
| Berglandschaft | [Bild](references/Medium_mountains.png) | Berge und höhenabhängige Farben sichtbar; Geometrie und Materialien weiterhin vereinfacht. |
| Sonnenuntergang | [Bild](references/Medium_sunset.png) | Niedriger Sonnenstand verändert Schatten; kein überzeugender Abendhimmel. |
| See | [Bild](references/Medium_lake.png) | Wasserfläche und Becken sichtbar; kaum Reflexion, keine Wellen oder Uferdetails. |
| Wald | [Bild](references/Medium_forest.png) | Einzelner Kegelbaum, kein tatsächlicher Wald und keine unterschiedlichen Arten. |
| Wolken | [Bild](references/Medium_clouds.png) | Geometrische Scheiben statt volumetrischer Wolken. |
| Bodennah | [Bild](references/Medium_ground.png) | Begrenzte Oberflächendetails; feine Linie auch im monolithischen Gelände sichtbar. |
| Große Höhe | [Bild](references/Medium_high_altitude.png) | Begrenzter 2-km-Ausschnitt und Weltkanten sichtbar; keine große gestreamte Welt. |

Die gespeicherten 960×540-Referenzen wurden erneut gerendert und mit einem
expliziten Grenzwert von 1/255 mittlerer RGB-Abweichung verglichen. In dieser
Umgebung bestanden alle sieben und waren pixelgleich. Andere Geräte oder Treiber
können Abweichungen verursachen; Bildänderungen sind zusätzlich visuell zu prüfen.

Für die experimentelle Kachelansicht liegen [Boden- und Höhenvergleiche](streaming_references/)
vor. Sie zeigen erwartete Geometrieunterschiede durch LOD; automatische Differenzen
sind weder ein Qualitätsurteil noch eine Leistungsmessung. Die Ursache der auch
im monolithischen Gelände sichtbaren feinen Linie bleibt offen.

Die ergänzende [10-km-Ansicht](altitude/extreme_after.png) prüft das
experimentelle Streaming nach Höhen-/Sichtweitenanpassung: 64 Kacheln verbleiben
in LOD 2. Der sichtbare kleine quadratische Ausschnitt zeigt gleichzeitig die
Grenze der heutigen Weltgröße. Vergleich und unveränderte Vorheransicht liegen
unter `altitude/`; Hardwareleistung bleibt ungemessen.
