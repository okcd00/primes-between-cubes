#!/usr/bin/env python3
"""Render the adaptive 41-root finite proof; reject any missing candidate."""
import argparse
import hashlib
import json
from pathlib import Path
from sweep import ROOT, roots, witness, witness_with_root
from render_one_factor import root_certs

EXPECTED = "846850f65b67ab03d5d1b2bbfe3a2dd5dc31c1ff0a6a09d59320c4078781119c"

def splice(xs):
    while len(xs) > 1:
        xs = [f"(splice {xs[i]} {xs[i+1]})" if i+1 < len(xs)
              else xs[i] for i in range(0,len(xs),2)]
    return xs[0]

def write(path, lines):
    path.write_text("\n".join(lines)+"\n", encoding="utf-8")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--output", type=Path, default=Path("FiniteAdaptive"))
    out=ap.parse_args().output
    table = [roots(i,5) for i in range(16)]
    used, data = set(), {}
    digest = hashlib.sha256()
    for n in range(1,65535):
        w = witness(n)
        if w:
            w = (*w,ROOT)
        else:
            for r in table[n.bit_length()-1]:
                if w := witness_with_root(n,r): break
        if w is None:
            raise ValueError(f"missing adaptive witness at {n}; no partial file emitted")
        p,v,r = w
        used.add(r)
        data[n] = w
        digest.update(json.dumps([n,p,v,r],separators=(",",":")).encode()+b"\n")
    if digest.hexdigest() != EXPECTED:
        raise ValueError("candidate digest changed")
    out.mkdir()
    rs=sorted(used)
    c = {}
    for r in rs: root_certs(r,c)
    cs = ", ".join(f"⟨{p}, {a}, {fs}⟩" for p,(a,fs) in sorted(c.items()))
    write(out/"Root.lean",[
        "import AdaptiveCore", "namespace CubePrime.Adaptive", "set_option maxRecDepth 8192",
        "set_option maxHeartbeats 0", f"def adaptiveRoots : List ℕ := {rs}",
        "theorem adaptiveRoots_prime : ∀ r ∈ adaptiveRoots, Nat.Prime r :=",
        f"  rootsOK_sound (certs := [{cs}]) (by decide +kernel)",
        "#print axioms adaptiveRoots_prime", "end CubePrime.Adaptive"])
    names=[]
    for g,lo in enumerate(range(1,65535,256)):
        hi=min(lo+256,65535)
        lines=["import FiniteAdaptive.Root","namespace CubePrime.Adaptive","open CubePrime.Pratt",
               "set_option maxRecDepth 8192","set_option maxHeartbeats 0"]
        parts=[]
        for b in range(lo,hi,64):
            e=min(b+64,hi); parts.append(f"part_{b}")
            pairs=", ".join(str(data[n]) for n in range(b,e))
            lines += [f"private def rows_{b} : List (ℕ × ℕ × ℕ) := [{pairs}]",
                 f"private theorem part_{b} (n : ℕ) (hl : {b} ≤ n) (hh : n < {e}) : CubeAt n :=",
                 f"  witnessOK_sound (start := {b}) (ps := rows_{b}) adaptiveRoots_prime",
                 "    (by decide +kernel) n hl hh"]
        gn=f"adaptive_{g:03d}"
        names.append(gn)
        lines += [f"theorem {gn} : ∀ n : ℕ, {lo} ≤ n → n < {hi} → CubeAt n :=",
                    "  "+splice(parts),"end CubePrime.Adaptive"]
        write(out/f"Group{g:03d}.lean",lines)
    write(out/"All.lean",
        [*(f"import FiniteAdaptive.Group{g:03d}" for g in range(len(names))),
         "namespace CubePrime.Adaptive","open CubePrime.Pratt","set_option maxRecDepth 8192",
         "theorem finite_cube_range : ∀ n : ℕ, 1 ≤ n → n < 65535 → CubeAt n :=",
         "  "+splice(names),"#print axioms finite_cube_range","end CubePrime.Adaptive"])
    print(f"adaptive_roots={len(rs)} root_certificates={len(c)} witnesses={len(data)} sha256={EXPECTED}")

if __name__=="__main__":
    main()
