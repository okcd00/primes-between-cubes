#!/usr/bin/env python3
"""Experimental scope audit for dense Lean4Export 3.1.0 name IDs.

This recognizes a few exact Lean names with one byte per name. It does NOT
check expressions, theorem bodies, statement equality, or kernel acceptance.
Use the pinned independent verifier unchanged for proof acceptance.
"""
import argparse
import json

LEAN = "819816b2e0a3bf405af45ae5c7af2491d8f5bee6"
CORE = {"propext", "Classical.choice", "Quot.sound"}
RH = {"riemannHypothesis"}
CUBES = {"CubePrime.primeBetweenCubes", "CubePrime.primeStrictlyBetweenConsecutiveCubes"}
FINITE = {"CubePrime.Pratt.group_000"}
ROLES = {
    "rh-provider": (CORE, RH),
    "bridge": (CORE | RH, CUBES),
    "exact-challenge": (CUBES | {"propext"}, set()),
    "final": (CORE, CUBES | RH),
    "finite-fixture": (CORE, FINITE),
}


def audit(stream, role):
    want_axioms, want_theorems = ROLES[role]
    watched_theorems = RH | CUBES | (FINITE if role == "finite-fixture" else set())
    # 0 is an irrelevant path, 1 the root. Relevant trie edges are exact
    # string components, not a flattened name or a numeric suffix.
    edges, terminal = {}, {}
    next_state = 2
    for name in sorted(CORE | watched_theorems):
        state = 1
        for part in name.split("."):
            if (state, part) not in edges:
                edges[state, part] = next_state
                next_state += 1
            state = edges[state, part]
        terminal[state] = name
    states = bytearray([1])
    meta = json.loads(next(stream))["meta"]
    if meta["lean"]["githash"] != LEAN or meta["format"]["version"] != "3.1.0":
        raise ValueError("unexpected Lean or export format pin")

    def state_at(index):
        if type(index) is not int or not 0 <= index < len(states):
            raise ValueError("name reference out of range")
        return states[index]

    axioms, theorems = set(), set()
    for line in stream:
        obj = json.loads(line)
        if not isinstance(obj, dict):
            raise ValueError("non-object export record")
        if "in" in obj:
            if "axiom" in obj or "thm" in obj:
                raise ValueError("ambiguous role record")
            index = obj["in"]
            if type(index) is not int or index != len(states) or ("str" in obj) == ("num" in obj):
                raise ValueError("name IDs must be dense and sequential")
            if "str" in obj:
                entry = obj["str"]
                parent = state_at(entry["pre"])
                part = entry["str"]
                if not isinstance(part, str):
                    raise ValueError("non-string name component")
                states.append(edges.get((parent, part), 0) if parent else 0)
            else:
                entry = obj["num"]
                state_at(entry["pre"])
                if type(entry["i"]) is not int or entry["i"] < 0:
                    raise ValueError("invalid numeric name component")
                states.append(0)
        elif "axiom" in obj:
            if "thm" in obj:
                raise ValueError("ambiguous role record")
            name = terminal.get(state_at(obj["axiom"]["name"]))
            if name not in want_axioms or name in axioms:
                raise ValueError("unexpected or duplicate axiom")
            axioms.add(name)
        elif "thm" in obj:
            name = terminal.get(state_at(obj["thm"]["name"]))
            if name in watched_theorems:
                if name in theorems:
                    raise ValueError("duplicate watched theorem")
                theorems.add(name)
    if axioms != want_axioms or theorems != want_theorems:
        raise ValueError(f"{role}: unexpected axiom set or watched theorem roles")
    return {"role": role, "axioms": sorted(axioms), "watched_theorems": sorted(theorems),
            "names": len(states) - 1, "name_table_bytes": len(states),
            "scope_only_not_kernel_check": True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("role", choices=ROLES)
    parser.add_argument("export")
    args = parser.parse_args()
    try:
        with open(args.export, encoding="utf-8") as handle:
            print(json.dumps(audit(handle, args.role), sort_keys=True))
    except (ValueError, KeyError, TypeError, StopIteration, OSError) as error:
        parser.exit(1, f"Scope audit failed: {error}\n")


if __name__ == "__main__":
    main()
