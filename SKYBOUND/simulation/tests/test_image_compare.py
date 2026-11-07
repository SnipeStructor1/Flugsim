import importlib.util
from pathlib import Path
import tempfile
import unittest

try:
    from PIL import Image
except ImportError:
    Image = None

path = Path(__file__).resolve().parents[2] / 'scripts/compare_images.py'
spec = importlib.util.spec_from_file_location('compare_images', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


@unittest.skipIf(Image is None, 'Pillow unavailable; image comparison tests skipped')
class ImageComparisonTests(unittest.TestCase):
    def test_identical_and_single_pixel(self):
        with tempfile.TemporaryDirectory() as directory:
            original = Path(directory) / 'original.png'
            changed = Path(directory) / 'changed.png'
            image = Image.new('RGB', (2, 2), (0, 0, 0))
            image.save(original)
            same = module.compare(original, original)
            self.assertEqual(same['mean_absolute_rgb_difference_0_255'], 0)
            self.assertEqual(same['changed_pixels'], 0)
            image.putpixel((0, 0), (12, 0, 0))
            image.save(changed)
            result = module.compare(original, changed)
            self.assertEqual(result['mean_absolute_rgb_difference_0_255'], 1)
            self.assertEqual(result['changed_fraction'], 0.25)

    def test_size_and_threshold_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            a, b = Path(directory) / 'a.png', Path(directory) / 'b.png'
            Image.new('RGB', (2, 2)).save(a)
            Image.new('RGB', (3, 2)).save(b)
            with self.assertRaises(ValueError):
                module.compare(a, b)
            with self.assertRaises(ValueError):
                module.compare(a, a, -1)
