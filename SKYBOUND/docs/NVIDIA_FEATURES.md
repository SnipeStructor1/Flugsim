# NVIDIA-Funktionen – Quellenprüfung 2026-11-07

Die offiziellen Streamline-Guides wurden gelesen (Repository `NVIDIA-RTX/Streamline`,
Commit `625db07d4bca5abc67d781c42af7e7fb0761f1b6`, README Version 2.14.16).
Das belegt SDK-Fähigkeiten, **keine fertige Godot-/O3DE-Integration**.
Keine SDK-Binärdateien oder Plugins installiert; alle Funktionen im Benchmark aus.

| Funktion | Offizieller Integrationsvertrag | SKYBOUND / beide Engines |
| --- | --- | --- |
| DLSS Super Resolution | Farb-, Tiefen-, Bewegungsvektorbuffer, Render-/Outputauflösung, Jitter/Kameradaten, Belichtung bzw. Auto-Exposure; Laufzeit-Capabilityprüfung [N1] | Eigene Renderer-/SDK-Integration E; kein verifiziertes Engineplugin |
| DLAA | Im DLSS-Guide eigener DLAA-Presetpfad; native Eingabe-/Ausgabegröße und unterstützter Modus nötig [N1] | Nicht aktiviert / NICHT GETESTET |
| Ray Reconstruction | Eigenes DLSS-RR-Feature mit passender Beleuchtungs-/Geometrieinformation; nicht automatisch durch DLSS SR vorhanden [N2] | Kein integrierter RR-Pfad / NICHT GETESTET |
| Frame Generation | Device-/Swapchain-Hooks, Buffer-Lebenszeiten, HUD-/UI-Behandlung, Motion/Depth und Reflex-Integration prüfen [N3] | Kein FG-Pfad; native Benchmarks ohne FG |
| Multi Frame Generation | Eigener Modus/Multiplier; Support vom konkreten Adapter, Treiber und System abhängig, zur Laufzeit abfragen [N3] | Blackwell-Ziel allein ist kein Nachweis; NICHT GETESTET |
| Reflex | `slReflexSleep`, PCL-Marker und Low-Latency-Featureabfrage; PCL-Statistiken und Low-Latency-Fähigkeit unterscheiden [N4] | Noch kein Markierungs-/Sleep-Pfad / NICHT GETESTET |

Der gelesene FG-Guide unterscheidet feste Multi-Frame-Multiplikatoren von
**Dynamic MFG**. Für Dynamic MFG nennt er unter anderem D3D12 als derzeitige
Voraussetzung; Vulkan-Unterstützung anderer FG-Pfade darf damit nicht verwechselt
werden. Jede Aussage muss gegen die später tatsächlich gewählte SDK-Version
geprüft werden. Keine feste SDK-Mindesttreiberversion für alle Features erfinden.

## Lizenz und Distribution

Der Streamline-Wrapper ist offen verfügbar; der gelesene Lizenztext enthält
MIT-Bedingungen und einen Verweis auf gesonderte Nsight-Perf-SDK-Bedingungen [N5].
Die README stellt klar: Der DLSS-G-Teil liegt als vorgefertigtes Plugin vor und
lässt sich nicht vollständig selbst bauen. Seit Streamline 2.7.32 werden SDK-
Binärartefakte getrennt über Releases bezogen. Offene Wrapperlizenz bedeutet daher
nicht, dass alle NVIDIA-Binärkomponenten automatisch dieselben Rechte besitzen.

Vor SDK-Aufnahme: gewählten Release einfrieren, zugehörige DLSS-/NGX-/Redistribution-
Bedingungen lesen, notwendige App-ID/Anmeldung klären und signierte produktive DLLs
verwenden. Diese Integrations-/Distributionsfreigabe ist noch offen. Die erteilte
Downloadfreigabe ist kein Ersatz für eine passende Lizenz.

## Messregeln

FG/MFG später in separaten Datensätzen mit Basis-FPS, generierten Presents,
Latenz und Artefakten prüfen. Niemals generierte FPS in die native 60-FPS-Baseline
mischen. Reflex-Latenz lässt sich nicht aus Main-Loop-Frametimes ableiten.
NVIDIA-SMI ist optionale Telemetrie und aktiviert keine NVIDIA-Renderfunktion.

## Gelesene offizielle Quellen

- [N1: DLSS](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/docs/ProgrammingGuideDLSS.md)
- [N2: Ray Reconstruction](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/docs/ProgrammingGuideDLSS_RR.md)
- [N3: Frame Generation / MFG](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/docs/ProgrammingGuideDLSS_G.md)
- [N4: Reflex](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/docs/ProgrammingGuideReflex.md)
- [N5: Lizenz](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/license.txt)
- [N6: README / Binärartefakte](https://github.com/NVIDIA-RTX/Streamline/blob/625db07d4bca5abc67d781c42af7e7fb0761f1b6/README.md)
