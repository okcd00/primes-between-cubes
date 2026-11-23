"""Classify pinned v2 summary receipts, not proof artifacts.

Supply runner summary.txt and, optionally, the discharge and match-final
summary.txt files. Never execute uploaded content. A consistent complete set
only opens independent artifact review; it cannot approve publication.
"""
from pathlib import Path
from collections import Counter
import re
import sys

PINS = {
    "lean":"4.33.1:819816b2e0a3bf405af45ae5c7af2491d8f5bee6",
    "mathlib":"0df444a360eaa60ab8c11dca51a86af692955474",
    "rh_source":"58afe6f4b8167e8945f7c82954b0fc477541f9d0",
    "cryptids":"3647718b5df22e1a61462dec0376bd204526285a",
    "candidate_sha256":"fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d",
    "finite_groups":"64/64",
}
STEPS = "cube_git cube_setup cube_data cube_dependencies cube_analytic cube_finite rh_git rh_build native_composition".split()
TARGETS = ("CubePrime.primeBetweenCubes", "CubePrime.primeStrictlyBetweenConsecutiveCubes")
AXIOMS = {"Classical.choice", "Quot.sound", "propext"}
PIN_CHECKER = "5dc36dc15b7bee891a02406b78a8ac816a47baad"

def parse(text, keys):
    values = {}
    for line in text.splitlines():
        m = re.fullmatch(r"([a-z_0-9]+)=(.*)", line)
        if m and m[1] in keys:
            if m[1] in values:
                raise ValueError("Duplicate field: " + m[1])
            values[m[1]] = m[2]
    return values

def need(values, expected):
    for k, v in expected.items():
        if values.get(k) != v:
            raise ValueError("Missing or mismatched field: " + k)

def native(text):
    lines = text.splitlines()
    if lines.count("CUBE_INTERNAL_RUN_V1") != 1:
        raise ValueError("Missing or ambiguous native header")
    d = parse(text, PINS.keys() | set(STEPS) | {"mode","exit","independent_export_replay","stopped_at"})
    for k, v in PINS.items():
        if k in d:
            need(d, {k:v})
    if d.get("mode") not in {"--run","--cube-only"}:
        raise ValueError("Unexpected native mode")
    if d.get("exit") is None:
        return "NATIVE_PENDING"
    if not re.fullmatch(r"(?:0|[1-9][0-9]{0,2})", d["exit"]):
        raise ValueError("Malformed native exit")
    need(d, {"independent_export_replay":"NOT_RUN"})
    if d["exit"] != "0":
        if d.get("stopped_at") not in {"preflight", *STEPS}:
            raise ValueError("Missing stopped_at for failed runner")
        return "NATIVE_STOPPED " + d["stopped_at"]
    if "stopped_at" in d:
        raise ValueError("Conflicting success and stopped_at")
    need(d, PINS | dict.fromkeys(STEPS[:6], "PASS"))
    if d["mode"] == "--cube-only":
        need(d, {"native_composition":"NOT_RUN"})
        return "CUBE_ONLY_NOT_UNCONDITIONAL"
    need(d, dict.fromkeys(STEPS, "PASS"))
    for name in ("riemannHypothesis", *TARGETS):
        lines_for = [x.removeprefix(f"PASS {name}: ") for x in lines if x.startswith(f"PASS {name}: ")]
        if len(lines_for) != 1:
            raise ValueError("Missing or ambiguous native axiom receipt: " + name)
        tokens = lines_for[0].split(", ")
        if len(tokens) != len(set(tokens)) or not set(tokens) <= AXIOMS:
            raise ValueError("Unexpected native axiom receipt: " + name)
    return "NATIVE_RECEIPT_CONSISTENT"

def independent(text, mode):
    want = ("riemannHypothesis",) if mode == "discharge" else TARGETS
    expected = {"checker_source":PIN_CHECKER}
    if mode == "discharge":
        expected |= {
            "input_bytes":"568203380",
            "context_bytes":"61570595788",
            "bridge_sha256":"c062651bcb32445417250d8e342a11e78e76722b917730c993fa384a30a7aa23",
            "provider_sha256":"5ea74b912147c5c93cc2b6d70cc727cf908df2f62ac6a20480a3fa02f6be244e",
        }
    else:
        expected["isolated_challenge_sha256"] = "2c1dbb56f2c18a63b8f57e1cd010b0a2d140642299b0bda7249de6cdddd8aad4"
    d = parse(text, expected.keys() | {"checker_binary_sha256","candidate_final_sha256"})
    need(d, expected)
    for k in ("checker_binary_sha256",) if mode == "discharge" else ("checker_binary_sha256","candidate_final_sha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", d.get(k, "")):
            raise ValueError("Missing or malformed " + k)
    lines = text.splitlines()
    terminal = [x for x in lines if x.startswith("mode=")]
    if terminal != [f"mode={mode} step=compare_passed exit=0"]:
        raise ValueError("Missing or contradictory " + mode + " completion")
    accepted = [x for x in lines if x.startswith("con-leche: accepted ")]
    if len(accepted) != 1 or not re.fullmatch(rf"con-leche: accepted [1-9]\d* declarations, {len(want)} axioms justified by the solution \([1-9]\d* declarations accepted\) \(--verified\)", accepted[0]):
        raise ValueError("Missing distinct verified acceptance")
    got = [x for x in lines if x.startswith("con-leche: axiom ")]
    if Counter(got) != Counter(f"con-leche: axiom {x} justified by the solution" for x in want):
        raise ValueError("Unexpected discharge targets for " + mode)
    return d["checker_binary_sha256"]

def classify(n, discharge=None, final=None):
    status = native(n)
    if status != "NATIVE_RECEIPT_CONSISTENT":
        return status
    if discharge is None or final is None:
        return "NATIVE_RECEIPT_CONSISTENT INDEPENDENT_RECEIPTS_PENDING"
    same = independent(discharge, "discharge") == independent(final, "match-final")
    return "RECEIPTS_CONSISTENT_ARTIFACT_REVIEW_REQUIRED" + ("" if same else " DIFFERENT_PINNED_CHECKER_BUILDS")

def main(args):
    if len(args) not in (1, 3):
        raise ValueError("Usage: review_receipts.py NATIVE [DISCHARGE FINAL]")
    print(classify(*(Path(f).read_text(encoding="utf-8") for f in args)))

if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (ValueError, OSError) as err:
        sys.exit(str(err))
