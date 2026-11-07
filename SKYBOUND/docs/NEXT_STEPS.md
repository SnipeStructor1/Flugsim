# Nächste Schritte

Die Freigabe für offizielle Dokumentation und projektlokale Downloads ist erteilt.
Godot 4.7.2 wurde mit SHA-512 geprüft, offizielle Engine-/NVIDIA-Quellen ausgewertet
und portable Linux-Bildprüfwerkzeuge lokal entpackt. Keine erneute Freigabe für
bereits autorisierte Downloads nötig; keine systemweiten Programme installiert.

1. Windows-Zielhardware bereitstellen: GPU/Treiber, CPU und RAM dort erfassen.
   Die Cloud kann die RTX-5070-Performance nicht messen.
2. Python-/PowerShell-Starter sowie optionale Windows-/NVIDIA-Telemetrie dort
   validieren; tatsächliche Renderauflösung und Fensterzustand kontrollieren.
3. Vollständige native Messmatrix mit 30 s Warm-up, 60 s Messung und drei
   Wiederholungen ausführen. Präsentationszeiten extern gegenprüfen, anschließend
   mindestens 30 Minuten Speicher-/Streaming-Stresstest.
4. Produktionsgrafik ergänzen: PBR-Texturen, Terrain-LOD/Streaming, Wasser und
   volumetrische Wolken. Die bestehende Szene ist ein technischer Prototyp.
5. O3DE auf geeigneter Windows-/Ubuntu-Maschine mit ausreichendem SSD-Platz
   installieren und einen äquivalenten Adapter erstellen. Dokumentierter
   Quellbuildbedarf 100+ GB übersteigt die rund 60 GiB dieser Cloud.
6. Erst nach Szenenparität und Zielhardware-Messung eine gewichtete Engineentscheidung
   treffen. NVIDIA-SDKs nur mit versionspassendem Integrations- und Lizenznachweis.

Offene Voraussetzungen sind Hardware/Platz und tatsächliche Adapterentwicklung,
nicht mehr eine ausstehende Downloadfreigabe. Details in ENGINE_COMPARISON.md.

Die Cloud-Felder `install_script` und `start_skill` sind als Entwurf gespeichert.
Für künftige Tasks den Entwurf in den Umgebungseinstellungen prüfen und speichern,
dann die Umgebung veröffentlichen. Das ist noch nicht erfolgt. Projektdateien sind
aktuell uncommittet im Workspace; der zuvor leere Remote ist keine Quelle dieser
neuen Dateien. Eine frische Wiederherstellung wurde nicht unabhängig getestet.
