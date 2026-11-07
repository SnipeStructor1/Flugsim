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
