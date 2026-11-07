"""Analytic fixtures, not benchmark measurements."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

path = Path(__file__).resolve().parents[2] / 'benchmarks/tools/analyze.py'
spec = importlib.util.spec_from_file_location('analyze', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class AnalysisTests(unittest.TestCase):
    def analyze(self, rows):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'frames.csv'
            path.write_text('frame,elapsed_s,frametime_ms\n' + rows)
            return module.analyze(path)

    def test_constant_intervals(self):
        result = self.analyze('0,0.01,10\n1,0.02,10\n2,0.03,10\n')
        self.assertEqual(result['average_fps'], 100)
        self.assertEqual(result['one_percent_low_fps'], 100)
        self.assertEqual(result['p95_ms'], 10)

    def test_outlier_and_percentiles(self):
        rows = ''.join(f'{i},{(i+1)*.01},10\n' for i in range(99)) + '99,1.09,100\n'
        result = self.analyze(rows)
        self.assertAlmostEqual(result['average_fps'], 100000 / 1090)
        self.assertEqual(result['one_percent_low_fps'], 10)
        self.assertAlmostEqual(result['p99_ms'], 10.9)

    def test_invalid_samples(self):
        for rows in ['', '0,0.01,10\n', '0,0.01,nan\n1,0.02,10\n', '0,0.01,-1\n1,0.02,10\n', '0,0.02,10\n1,0.01,10\n', '1,0.01,10\n2,0.02,10\n', '0,0.01,10\n1,0.10,10\n']:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                self.analyze(rows)

    def test_failed_run_does_not_appear_as_a_measurement(self):
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory) / 'report.md'
            summary = {'status': 'FAIL', 'mode': 'software-validation', 'runs': [
                {'status': 'FAIL', 'profile': 'Ultra', 'width': 1920, 'height': 1080,
                 'repeat': 1, 'metrics': {'average_fps': 99, 'p95_ms': 10, 'p99_ms': 10}}]}
            module.write_report(summary, report)
            text = report.read_text()
            self.assertNotIn('| Ultra |', text)
            self.assertIn('CPU SOFTWARE RENDERER ONLY', text)

    def test_percentile_interpolation(self):
        self.assertEqual(module.percentile([1,2,3,4], .5), 2.5)


if __name__ == '__main__':
    unittest.main()
