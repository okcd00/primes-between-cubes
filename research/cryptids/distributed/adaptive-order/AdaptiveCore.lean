import OneFactorCore

namespace CubePrime.Adaptive
open CubePrime.Pratt CubePrime.OneFactor

def rootsOK (roots : List ℕ) (certs : List Cert) : Bool :=
  match foldCheck [2] certs with
  | none => false
  | some known => roots.all known.contains

theorem rootsOK_sound {roots : List ℕ} {certs : List Cert} (h : rootsOK roots certs = true) :
    ∀ r ∈ roots, Nat.Prime r := by
  unfold rootsOK at h
  cases hh : foldCheck [2] certs with
  | none => simp [hh] at h
  | some known =>
    simp only [hh, List.all_eq_true] at h
    intro r hr
    exact foldCheck_sound (fun q hq => List.mem_singleton.mp hq ▸ Nat.prime_two)
      hh r (List.contains_iff_mem.mp (h r hr))

def witnessOK (roots : List ℕ) (start : ℕ) : List (ℕ × ℕ × ℕ) → Bool
  | [] => true
  | (p, v, r) :: ps => roots.contains r && certOK r p v &&
      decide (start ^ 3 < p) && decide (p < (start + 1) ^ 3) &&
      witnessOK roots (start + 1) ps

theorem witnessOK_sound {roots : List ℕ} {start : ℕ} {ps : List (ℕ × ℕ × ℕ)}
    (hr : ∀ r ∈ roots, Nat.Prime r) (hw : witnessOK roots start ps = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) : CubeAt n := by
  induction ps generalizing start with
  | nil => simp only [List.length_nil, Nat.add_zero] at hhi; omega
  | cons pv ps ih =>
    rcases pv with ⟨p,v,r⟩
    simp only [witnessOK, Bool.and_eq_true, decide_eq_true_eq] at hw
    obtain ⟨⟨⟨⟨hmem, hcert⟩, hleft⟩, hright⟩, hrest⟩ := hw
    by_cases ht : n = start
    · subst n
      exact ⟨p, certOK_sound (hr r (List.contains_iff_mem.mp hmem)) hcert, hleft, hright⟩
    · have hb : n < (start + 1) + ps.length := by
        simp only [List.length_cons] at hhi
        omega
      exact ih hrest (by omega) hb

#print axioms rootsOK_sound
#print axioms witnessOK_sound
end CubePrime.Adaptive
