# Herkunft und Lizenzen

Das Flugzeug und die Shader werden aus eigenem Projektcode erzeugt; externe Assets sind unten aufgeführt.
Die unten einzeln genannten externen Texturen sind beigelegt; keine externen Flugzeugmodelle, Plugins oder SDKs.
Godot ist ein extern bereitgestelltes Werkzeug und wird nicht im Repository verteilt.
Vor der Distribution Engine-/Drittkomponentenhinweise prüfen und beilegen.
Die Projektlizenz ist vom Eigentümer noch festzulegen; keine pauschale Lizenz
für fremde Engine-/SDK-Komponenten ableiten.

`flight/assets/raptor.glb` wird projektintern aus
`tools/aircraft/build_raptor.py` erzeugt. Blender dient nur als Werkzeug;
das Modell enthält keine übernommenen Dritt-Assets.

## Felsmaterial – Godot Demo Projects

Dateien `benchmarks/godot/flight/assets/rock/rock_albedo.jpg`,
`rock_rough.jpg`, `rock_depth.jpg` und `rock_normal.jpg` stammen aus dem
[Material-Test-Demo](https://github.com/godotengine/godot-demo-projects/tree/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/3d/material_testers/test_materials),
Commit `b761b4cd5718a7118f2c95eb55f181d0a5f004f1`. Im Original heißt die
Normalkarte `rock_metal.jpg`; die Demo verwendet sie als Normaltextur.
Copyright (c) 2014-present Godot Engine contributors; Copyright (c) 2007-2014
Juan Linietsky, Ariel Manzur. Lizenz: MIT, vollständiger Text in
[godot-demo-projects-MIT.txt](godot-demo-projects-MIT.txt).
Die Texturen sind unverändert; der Shader entsättigt das Albedo bei der Darstellung.

## Baum – Ricardo Sanchez, CC BY 4.0

`benchmarks/godot/flight/assets/vegetation/tree.glb` ist eine mit
`tools/vegetation/build_tree.py` skalierte und zusammengefasste Fassung von
[tree low-poly](https://sketchfab.com/3d-models/tree-low-poly-4cd243eb74c74b3ea2190ebcec0439fb)
von [Ricardo Sanchez](https://sketchfab.com/380660711785),
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Quelle: die
[Godot-Demos](https://github.com/godotengine/godot-demo-projects/tree/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/3d/truck_town/town/tree),
Commit `b761b4cd5718a7118f2c95eb55f181d0a5f004f1`; der ursprüngliche
[Urheberhinweis](tree-low-poly-CC-BY-4.0.txt) liegt bei.

## Grastextur – Godot Demo Projects

`benchmarks/godot/flight/assets/grass/grass.webp` stammt aus dem
[Truck-Town-Demo](https://github.com/godotengine/godot-demo-projects/blob/b761b4cd5718a7118f2c95eb55f181d0a5f004f1/3d/truck_town/town/materials/grass.webp),
Commit `b761b4cd5718a7118f2c95eb55f181d0a5f004f1`; das Demo-Repository ist
MIT-lizenziert, siehe [godot-demo-projects-MIT.txt](godot-demo-projects-MIT.txt).
Die Textur selbst ist unverändert, die Darstellung im Shader ist abgetönt.

`flight/assets/vegetation/alpine_fir.glb` ist eine konisch umgeformte Variante
des oben genannten CC-BY-4.0-Baumes von Ricardo Sanchez; reproduzierbar über
`tools/vegetation/build_conifer.py`. Die gleichen Namensnennungen gelten.

## Wald- und Felsboden – ambientCG, CC0

`flight/assets/ambientcg/ground037_alb_ht.png` und
`ground037_nrm_rgh.png`: ambientCG Ground037; `rock023_alb_ht.png` und
`rock023_nrm_rgh.png`: ambientCG Rock023. Bezogen über
[Terrain3D](https://github.com/TokisanGames/Terrain3D/tree/852b6c9742bcfebab30d06857c547e2d8daa2f60/project/demo/assets/textures)
Commit `852b6c9742bcfebab30d06857c547e2d8daa2f60`. Der
[beigelegte Herkunfts- und Lizenzhinweis](terrain3d-ambientcg-asset-licenses.txt)
kennzeichnet diese ambientCG-Assets als CC0 1.0. Jeweils 1024×1024 Pixel;
RGB/Alpha packen Albedo/Höhe und Normale/Rauheit. Die direkten ambientCG-Seiten
waren in dieser Umgebung nicht erreichbar; die Quellenzuordnung stammt aus
dem mit den Bildern veröffentlichten Terrain3D-Hinweis.

## Wiesenpflanzen – projekterzeugt

`flight/assets/vegetation/groundcover.glb` wird aus
`tools/vegetation/build_groundcover.py` in Blender generiert und enthält
keine externen Texturen oder übernommenen Pflanzenmodelle.

## 25 Buschvarianten

Die Modelle `bush_00.glb`–`bush_09.glb` basieren auf dem MIT-lizenzierten
Generator Groundcover Gift von Jalapeño Seed Productions. Copyright und
Lizenztexte sowie genaue Version und Erzeugungsschritte stehen in
`benchmarks/godot/flight/assets/vegetation/bushes/README.md` und den dort
beigelegten `JALAPENOSEED-*`-Dateien. Modelle `bush_10.glb`–`bush_24.glb`
sind aus eigenem prozeduralem Code erzeugt. Der Katalog enthält Hashes und
Quellen pro Variante.
