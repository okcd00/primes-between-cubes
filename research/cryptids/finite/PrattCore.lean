/-
Copyright 2026 Steve Hubbard (GoldbachLean).
Adapted from entries/dudek2014/LeanLab/Verifications/PrattCertificates.lean at
93b86c05bb441be2ac0b3f06cc4c8624f8e8d0eb (Apache-2.0), isolating its two
elementary kernel lemmas and adding a batched checker.
-/
import Mathlib.NumberTheory.LucasPrimality
import Mathlib.Tactic

namespace CubePrime.Pratt
/-- Binary modular power with fuel. -/
def pm : ℕ → ℕ → ℕ → ℕ → ℕ
  | 0, _, _, _ => 1
  | fuel + 1, a, e, m =>
    if e = 0 then 1 % m else
      let h := pm fuel a (e / 2) m
      if e % 2 = 1 then h * h % m * a % m else h * h % m

theorem pm_cast : ∀ fuel a e m, e < 2 ^ fuel → ((pm fuel a e m : ℕ) : ZMod m) = (a : ZMod m) ^ e := by
  intro fuel
  induction fuel with
  | zero => intro a e m he; simp at he; subst he; simp [pm]
  | succ k ih =>
    intro a e m he
    simp only [pm]
    by_cases h0 : e = 0
    · subst h0; simp
    · rw [if_neg h0]
      have hlt : e / 2 < 2 ^ k := by rw [pow_succ] at he; omega
      have IH := ih a (e / 2) m hlt
      have he2 : e = 2 * (e / 2) + e % 2 := (Nat.div_add_mod e 2).symm
      by_cases h1 : e % 2 = 1
      · rw [if_pos h1]
        simp only [Nat.cast_mul, ZMod.natCast_mod, IH]
        conv_rhs => rw [he2, h1, pow_add, pow_mul, pow_one]
        ring
      · rw [if_neg h1]
        have h1' : e % 2 = 0 := by omega
        simp only [Nat.cast_mul, ZMod.natCast_mod, IH]
        conv_rhs => rw [he2, h1', add_zero, pow_mul]
        ring

/-- Lucas' test with a listed factorization of `p - 1`. -/
theorem pratt (p a : ℕ) (L : List (ℕ × ℕ)) (hp : p < 2 ^ 64)
    (hprod : (L.map fun x => x.1 ^ x.2).prod = p - 1) (hprimes : ∀ x ∈ L, x.1.Prime)
    (hpow : pm 64 a (p - 1) p = 1 % p)
    (hnot : ∀ x ∈ L, pm 64 a ((p - 1) / x.1) p % p ≠ 1 % p) : p.Prime := by
  apply lucas_primality p (a : ZMod p)
  · rw [← pm_cast 64 a (p - 1) p (by omega), hpow]
    simp
  · intro q hq hqd heq
    rw [← hprod] at hqd
    obtain ⟨y, hy, hyd⟩ := (Nat.prime_iff.mp hq).dvd_prod_iff.mp hqd
    obtain ⟨x, hx, rfl⟩ := List.mem_map.mp hy
    have hqx : q = x.1 :=
      (Nat.prime_dvd_prime_iff_eq hq (hprimes x hx)).mp (hq.dvd_of_dvd_pow hyd)
    subst hqx
    apply hnot x hx
    have h2 : (p - 1) / x.1 < 2 ^ 64 := lt_of_le_of_lt (Nat.div_le_self _ _) (by omega)
    rw [← pm_cast 64 a _ p h2] at heq
    have := (ZMod.natCast_eq_natCast_iff' _ 1 p).mp (by rw [heq]; simp)
    simpa using this


structure Cert where
  p : ℕ
  a : ℕ
  factors : List (ℕ × ℕ)
  deriving Repr

def entryOK (known : List ℕ) (c : Cert) : Bool :=
  decide (c.p < 2 ^ 64) &&
  decide ((c.factors.map fun v => v.1 ^ v.2).prod = c.p - 1) &&
  c.factors.all (fun v => known.contains v.1) &&
  decide (pm 64 c.a (c.p - 1) c.p = 1 % c.p) &&
  c.factors.all (fun v => decide (pm 64 c.a ((c.p - 1) / v.1) c.p % c.p ≠ 1 % c.p))

theorem entryOK_sound {known : List ℕ} {c : Cert}
    (hknown : ∀ p ∈ known, p.Prime) (hc : entryOK known c = true) : c.p.Prime := by
  simp only [entryOK, Bool.and_eq_true, decide_eq_true_eq, List.all_eq_true] at hc
  obtain ⟨⟨⟨⟨hsize, hprod⟩, hcontains⟩, hmod⟩, hnot⟩ := hc
  exact pratt c.p c.a c.factors hsize hprod
    (fun v hv => hknown v.1 (List.contains_iff_mem.mp (hcontains v hv))) hmod hnot

def foldCheck (known : List ℕ) : List Cert → Option (List ℕ)
  | [] => some known
  | c :: cs => if entryOK known c then foldCheck (c.p :: known) cs else none

theorem foldCheck_sound {certs : List Cert} {known out : List ℕ}
    (hknown : ∀ p ∈ known, p.Prime) (hc : foldCheck known certs = some out) :
    ∀ p ∈ out, p.Prime := by
  induction certs generalizing known with
  | nil =>
    simp only [foldCheck, Option.some.injEq] at hc
    subst out
    exact hknown
  | cons c cs ih =>
    simp only [foldCheck] at hc
    split at hc
    next he =>
      apply ih (known := c.p :: known) _ hc
      intro p hp
      rcases List.mem_cons.mp hp with rfl | hp
      · exact entryOK_sound hknown he
      · exact hknown p hp
    next => simp at hc

def checkWitnesses (known : List ℕ) (start : ℕ) : List ℕ → Bool
  | [] => true
  | p :: ps => known.contains p &&
      decide (start ^ 3 < p) && decide (p < (start + 1) ^ 3) &&
        checkWitnesses known (start + 1) ps

theorem checkWitnesses_sound {known : List ℕ} {start : ℕ} {ps : List ℕ}
    (hknown : ∀ p ∈ known, p.Prime) (hc : checkWitnesses known start ps = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) :
    ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 := by
  induction ps generalizing start with
  | nil => simp only [List.length_nil, Nat.add_zero] at hhi; omega
  | cons p ps ih =>
    simp only [checkWitnesses, Bool.and_eq_true, decide_eq_true_eq] at hc
    obtain ⟨⟨⟨hp, hpl⟩, hpu⟩, hps⟩ := hc
    by_cases he : n = start
    · subst n
      exact ⟨p, hknown p (List.contains_iff_mem.mp hp), hpl, hpu⟩
    · have hstep : start + 1 ≤ n := by omega
      have hnext : n < (start + 1) + ps.length := by simp only [List.length_cons] at hhi; omega
      exact ih hps hstep hnext

def checkBatch (start : ℕ) (ps : List ℕ) (certs : List Cert) : Bool :=
  match foldCheck [2] certs with
  | none => false
  | some known => checkWitnesses known start ps

theorem checkBatch_sound {start : ℕ} {ps : List ℕ} {certs : List Cert}
    (hc : checkBatch start ps certs = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) :
    ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3 := by
  unfold checkBatch at hc
  cases he : foldCheck [2] certs with
  | none => simp [he] at hc
  | some known =>
    simp only [he] at hc
    apply checkWitnesses_sound (known := known) _ hc n hlo hhi
    apply foldCheck_sound _ he
    intro p hp
    rcases List.mem_singleton.mp hp with rfl
    exact Nat.prime_two

def CubeAt (n : ℕ) : Prop :=
  ∃ p : ℕ, p.Prime ∧ n ^ 3 < p ∧ p < (n + 1) ^ 3

theorem splice {a b c : ℕ}
    (hl : ∀ n : ℕ, a ≤ n → n < b → CubeAt n)
    (hr : ∀ n : ℕ, b ≤ n → n < c → CubeAt n)
    (n : ℕ) (hlo : a ≤ n) (hhi : n < c) : CubeAt n := by
  by_cases h : n < b
  · exact hl n hlo h
  · exact hr n (not_lt.mp h) hhi

#print axioms checkBatch_sound
end CubePrime.Pratt
