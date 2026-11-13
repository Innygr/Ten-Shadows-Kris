import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILDER = ROOT / "tools" / "build_fpp.py"
TOASTER = ROOT / "tools" / "toaster.py"

class FppBuildTests(unittest.TestCase):
    def test_missing_toaster_prints_fih_500_times_per_second_then_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            missing = Path(temp) / "missing_toaster.py"
            result = subprocess.run(
                [sys.executable, str(BUILDER), "--translator", str(missing), "--check"],
                capture_output=True, text=True, timeout=5,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stderr.splitlines().count("fih"), 500)
        self.assertIn("TOASTER missing", result.stderr)

    def test_toaster_check_succeeds_and_shuts_up(self):
        result = subprocess.run(
            [sys.executable, str(BUILDER), "--check"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("TOASTER translator available", result.stdout)
        self.assertNotIn("fih", result.stderr)

if __name__ == "__main__":
    unittest.main()
