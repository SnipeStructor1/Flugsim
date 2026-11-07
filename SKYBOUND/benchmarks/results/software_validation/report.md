# SKYBOUND Benchmark Report

Status: SOFTWARE_PIPELINE_VALIDATED_NOT_TARGET_HARDWARE

1%-Low = 1000 / mean(slowest ceil(N × 0.01) frame intervals).

| Profile | Resolution | Run | Average FPS | P95 ms | P99 ms |
| --- | --- | --- | --- | --- | --- |
| Medium | 1920×1080 | 1 | 1.33 | 1035.038 | 1109.857 |
| Medium | 1920×1080 | 2 | 1.32 | 1005.564 | 1328.332 |
| Medium | 1920×1080 | 3 | 1.46 | 815.784 | 957.327 |

**CPU SOFTWARE RENDERER ONLY. These are pipeline-validation samples, not RTX-5070 performance.**

Raw intervals measure engine main-loop wall time, not GPU timestamps or display presents.
Telemetry: adapter-wide NVIDIA samples; absent/unsupported values remain null.
No cross-engine ranking without matched scenes and target-hardware runs.
