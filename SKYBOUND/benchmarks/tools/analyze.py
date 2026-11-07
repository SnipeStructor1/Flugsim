"""Strict analysis of real frame intervals; only Python standard library."""
import argparse
import csv
import json
import math
from pathlib import Path
from statistics import mean, median


def percentile(values, fraction):
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    lower = math.floor(position)
    upper = math.ceil(position)
    return ordered[lower] + (ordered[upper] - ordered[lower]) * (position - lower)


def analyze(path):
    values, elapsed = [], []
    with Path(path).open(newline='', encoding='utf-8') as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != ['frame', 'elapsed_s', 'frametime_ms']:
            raise ValueError('Unexpected CSV schema')
        for index, row in enumerate(reader):
            frame, timestamp, value = int(row['frame']), float(row['elapsed_s']), float(row['frametime_ms'])
            if frame != index or not math.isfinite(timestamp) or timestamp < 0:
                raise ValueError('Invalid frame sequence or timestamp')
            if not math.isfinite(value) or value <= 0:
                raise ValueError('Invalid frametime')
            if elapsed and timestamp <= elapsed[-1]:
                raise ValueError('Non-monotonic frame timestamps')
            if elapsed and abs((timestamp - elapsed[-1]) * 1000 - value) > 0.1:
                raise ValueError('Timestamp/frametime mismatch')
            values.append(value)
            elapsed.append(timestamp)
    if len(values) < 2:
        raise ValueError('At least two measured frames required')
    slowest = sorted(values, reverse=True)[:math.ceil(len(values) * .01)]
    return {'frames': len(values), 'sampled_seconds': sum(values) / 1000,
            'average_fps': 1000 / mean(values), 'one_percent_low_fps': 1000 / mean(slowest),
            'median_ms': median(values), 'p95_ms': percentile(values, .95),
            'p99_ms': percentile(values, .99), 'max_ms': max(values)}


def write_report(summary, output):
    """Never convert smoke runs or absent samples into performance scores."""
    lines = ['# SKYBOUND Benchmark Report', '', f"Status: {summary['status']}", '',
             '1%-Low = 1000 / mean(slowest ceil(N × 0.01) frame intervals).', '',
             '| Profile | Resolution | Run | Average FPS | P95 ms | P99 ms |',
             '| --- | --- | --- | --- | --- | --- |']
    for run in summary['runs']:
        if run.get('status') == 'PASS' and run.get('metrics'):
            m = run['metrics']
            lines.append(f"| {run['profile']} | {run['width']}×{run['height']} | {run['repeat']} | {m['average_fps']:.2f} | {m['p95_ms']:.3f} | {m['p99_ms']:.3f} |")
    if summary['mode'] == 'software-validation':
        lines += ['', '**CPU SOFTWARE RENDERER ONLY. These are pipeline-validation samples, not RTX-5070 performance.**']
    if summary['mode'] == 'smoke':
        lines += ['', 'Headless functional checks only. Rendering and performance: NICHT GETESTET.']
    lines += ['', 'Raw intervals measure engine main-loop wall time, not GPU timestamps or display presents.',
              'Telemetry: adapter-wide NVIDIA samples; absent/unsupported values remain null.',
              'No cross-engine ranking without matched scenes and target-hardware runs.']
    Path(output).write_text('\n'.join(lines) + '\n', encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('csv', type=Path)
    args = parser.parse_args()
    print(json.dumps(analyze(args.csv), indent=2, allow_nan=False))
