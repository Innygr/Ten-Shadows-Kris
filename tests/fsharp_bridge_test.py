import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from fsharp_bridge import BridgeError, fpp_to_fsharp, fsharp_to_fpp, fsharp_to_lua


SAMPLE = (ROOT / "examples" / "hello.fs").read_text(encoding="utf-8")


class FSharpBridgeTests(unittest.TestCase):
    def test_fsharp_to_fpp(self):
        translated = fsharp_to_fpp(SAMPLE)
        self.assertIn("fonction main() {", translated)
        self.assertIn("si chaos > 50 {", translated)
        self.assertIn("} sinon {", translated)
        self.assertIn('afficher("F# says RANDOM BS GO!")', translated)

    def test_fsharp_to_lua(self):
        translated = fsharp_to_lua(SAMPLE)
        self.assertIn("function main()", translated)
        self.assertIn("if chaos > 50 then", translated)
        self.assertIn('print("F# says RANDOM BS GO!")', translated)
        self.assertIn("return 0", translated)

    def test_fpp_to_fsharp(self):
        fpp = '''fonction main() {
    local chaos = 100
    si chaos > 50 {
        afficher("F++ says bonjour")
    } sinon {
        afficher("F++ says au revoir")
    }
    retourner 0
}
main()
'''
        translated = fpp_to_fsharp(fpp)
        self.assertIn("let main () =", translated)
        self.assertIn("if chaos > 50 then", translated)
        self.assertIn("else", translated)
        self.assertIn('printfn "F++ says bonjour"', translated)
        self.assertIn("main ()", translated)

    def test_bad_else_is_rejected(self):
        with self.assertRaises(BridgeError):
            fsharp_to_fpp("else\n")


if __name__ == "__main__":
    unittest.main()
