"""Compare same-size reference images; pixel differences do not assess visual quality."""
import argparse
import json
from pathlib import Path
import sys


def compare(reference, candidate, threshold=2):
    try:
        from PIL import Image, ImageChops, ImageStat
    except ImportError as error:
        raise RuntimeError('Pillow is required for image comparison; install it in a project-local Python environment') from error
    if not 0 <= threshold <= 255:
        raise ValueError('Threshold must be between 0 and 255')
    with Image.open(reference) as source, Image.open(candidate) as target:
        before = source.convert('RGB')
        after = target.convert('RGB')
        if before.size != after.size:
            raise ValueError(f'Image sizes differ: {before.size} versus {after.size}')
        difference = ImageChops.difference(before, after)
        means = ImageStat.Stat(difference).mean
        # A pixel changed if any RGB channel differs by more than the threshold.
        channels = difference.split()
        largest = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2])
        count = sum(largest.histogram()[threshold + 1:])
        pixels = before.width * before.height
        return {'width': before.width, 'height': before.height, 'mean_absolute_rgb_difference_0_255': sum(means) / 3,
                'changed_pixels': count, 'changed_fraction': count / pixels, 'channel_threshold': threshold,
                'interpretation': 'Pixel difference only; lighting, renderer and driver changes require human review.'}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference', type=Path)
    parser.add_argument('candidate', type=Path)
    parser.add_argument('--threshold', type=int, default=2)
    parser.add_argument('--max-mean-difference', type=float, help='Optional explicit failure threshold, 0–255')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    try:
        result = compare(args.reference, args.candidate, args.threshold)
        if args.max_mean_difference is not None and not 0 <= args.max_mean_difference <= 255:
            raise ValueError('Maximum mean difference must be between 0 and 255')
        result['reference'] = str(args.reference)
        result['candidate'] = str(args.candidate)
        result['within_limit'] = None if args.max_mean_difference is None else result['mean_absolute_rgb_difference_0_255'] <= args.max_mean_difference
        text = json.dumps(result, indent=2, allow_nan=False) + '\n'
        if args.output:
            args.output.write_text(text, encoding='utf-8')
        print(text, end='')
        return 1 if result['within_limit'] is False else 0
    except (OSError, ValueError, RuntimeError) as error:
        print(error, file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
