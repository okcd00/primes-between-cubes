import json
import unittest
from compact_role_audit import audit, LEAN

META = {"meta": {"lean": {"githash": LEAN}, "format": {"version": "3.1.0"}}}
NAME = lambda i, parent, part: {"in": i, "str": {"pre": parent, "str": part}}
AX = lambda i: {"axiom": {"name": i}}
THM = lambda i: {"thm": {"name": i}}
ROWS = [META, NAME(1,0,"propext"), NAME(2,0,"Classical"), NAME(3,2,"choice"),
        NAME(4,0,"Quot"), NAME(5,4,"sound"), NAME(6,0,"riemannHypothesis"),
        AX(1), AX(3), AX(5), THM(6)]


def run(rows):
    return audit(iter(map(json.dumps, rows)), "rh-provider")


class Tests(unittest.TestCase):
    def test_typed_names_only(self):
        self.assertEqual(run(ROWS)["watched_theorems"], ["riemannHypothesis"])
        with self.assertRaises(ValueError):
            run([*ROWS[:3], NAME(3,0,"Classical.choice"), *ROWS[4:]])

    def test_negative_controls(self):
        cases = {
            "extra-axiom": [*ROWS, NAME(7,0,"unsound"), AX(7)],
            "missing-rh": ROWS[:-1],
            "duplicate-rh": [*ROWS, THM(6)],
            "rh-is-axiom": [*ROWS[:-1], AX(6)],
            "early-name": [*ROWS[:3], NAME(3,8,"choice"), *ROWS[4:]],
            "sparse-name": [*ROWS, NAME(100000000,0,"irrelevant")],
            "ambiguous-role": [*ROWS, {**THM(6), **AX(1)}],
            "extra-rh-alias": [*ROWS, NAME(7,0,"riemannHypothesis"), THM(7)],
        }
        for name, rows in cases.items():
            with self.subTest(name=name), self.assertRaises(ValueError):
                run(rows)


if __name__ == "__main__":
    unittest.main()
