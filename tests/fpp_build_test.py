import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUILDER = ROOT / "tools" / "build_fpp.py"

class FppBuildTests(unittest.TestCase):
    def test_missing_translator_prints_requested_message(self):
        with tempfile.TemporaryDirectory() as temp:
            missing = Path(temp) / "missing_fpp.py"
            result = subprocess.run(
                [sys.executable, str(BUILDER), "--translator", str(missing), "--check"],
                capture_output=True, text=True,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("fih 500 times / minute", result.stderr)

    def test_translator_check_succeeds(self):
        result = subprocess.run(
            [sys.executable, str(BUILDER), "--check"],
            capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("F++ translator available", result.stdout)

if __name__ == "__main__":
    unittest.main()
