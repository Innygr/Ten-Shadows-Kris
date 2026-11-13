import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from fpp import FppError, transpile

class TranspilerTests(unittest.TestCase):
    def test_keywords_and_blocks(self):
        source = '''fonction main() {
    si ready {
        afficher("bonjour")
    } sinon {
        retourner rien
    }
}'''
        expected = '''function main()
    if ready then
        print("bonjour")
    else
        return nil
    end
end'''
        self.assertEqual(transpile(source), expected)

    def test_does_not_translate_strings_or_comments(self):
        source = '''-- afficher("not code")
afficher("si sinon fonction")'''
        self.assertEqual(transpile(source), '''-- afficher("not code")
print("si sinon fonction")''')

    def test_table_braces_are_preserved(self):
        source = '''local data = { name = "Kris", alive = vrai }
fonction get() {
    retourner data
}'''
        expected = '''local data = { name = "Kris", alive = true }
function get()
    return data
end'''
        self.assertEqual(transpile(source), expected)

    def test_unmatched_brace_fails(self):
        with self.assertRaises(FppError):
            transpile("fonction main() {")

if __name__ == "__main__":
    unittest.main()
