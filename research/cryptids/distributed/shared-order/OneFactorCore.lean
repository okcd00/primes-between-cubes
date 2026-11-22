import PrattCore
namespace CubePrime.OneFactor

theorem prime_of_order_cert {p r v : ℕ} (hp : 1 < p) (hr : r.Prime)
    (hs : p < r ^ 2) (hv : 1 ≤ v)
    (hpow : (v : ZMod p) ^ r = 1) (hg : (v-1).gcd p = 1) : p.Prime := by
  by_contra hn
  let q := p.minFac
  have hq : q.Prime := Nat.minFac_prime (by omega)
  have hqd : q ∣ p := Nat.minFac_dvd p
  have : NeZero q := ⟨hq.ne_zero⟩
  have : Fact q.Prime := ⟨hq⟩
  let w : ZMod q := (v : ZMod q)
  have hwr : w ^ r = 1 := by
    have h := congrArg (ZMod.castHom hqd (ZMod q)) hpow
    simp only [map_pow, map_natCast, map_one] at h
    exact h
  have hw0 : w ≠ 0 := by
    intro he
    rw [he, zero_pow hr.ne_zero] at hwr
    exact zero_ne_one hwr
  have hw1 : w ≠ 1 := by
    intro he
    have e : ((v-1 : ℕ) : ZMod q) = 0 := by
      rw [Nat.cast_sub hv, Nat.cast_one, show (v : ZMod q) = 1 from he, sub_self]
    have hd : q ∣ v-1 := Nat.modEq_zero_iff_dvd.mp
      ((ZMod.natCast_eq_natCast_iff (v-1) 0 q).mp (by simpa using e))
    have hg' := Nat.dvd_gcd hd hqd
    rw [hg, Nat.dvd_one] at hg'
    exact hq.ne_one hg'
  have ho : orderOf w = r := by
    rcases (Nat.dvd_prime hr).mp (orderOf_dvd_of_pow_eq_one hwr) with h | h
    · exact (hw1 (orderOf_eq_one_iff.mp h)).elim
    · exact h
  have hcard := (Nat.prime_iff_card_units q).mp hq
  have hwq : w ^ (q-1) = 1 := by
    let u : (ZMod q)ˣ := (isUnit_iff_ne_zero.mpr hw0).unit
    have h : u ^ Fintype.card (ZMod q)ˣ = 1 := pow_card_eq_one
    rw [hcard] at h
    have e := congrArg (fun v : (ZMod q)ˣ => (v : ZMod q)) h
    simpa [u] using e
  have hle := Nat.le_of_dvd (show 0 < q-1 from by have := hq.one_lt; omega)
    (show r ∣ q-1 from ho ▸ orderOf_dvd_of_pow_eq_one hwq)
  have hs' : q ^ 2 ≤ p := Nat.minFac_sq_le_self (by omega) hn
  exact (not_le_of_gt hs) ((Nat.pow_le_pow_left (show r ≤ q from by omega) 2).trans hs')

def certOK (r p v : ℕ) : Bool :=
  decide (1 < p) && decide (p < r^2) && decide (1 ≤ v) &&
  decide (r < 2^64) && decide (Pratt.pm 64 v r p = 1 % p) &&
  decide ((v-1).gcd p = 1)

theorem certOK_sound {r p v : ℕ} (hr : r.Prime) (hc : certOK r p v = true) : p.Prime := by
  simp only [certOK, Bool.and_eq_true, decide_eq_true_eq] at hc
  obtain ⟨⟨⟨⟨⟨hp, hs⟩, hv⟩, hsize⟩, hpow⟩, hg⟩ := hc
  refine prime_of_order_cert hp hr hs hv ?_ hg
  rw [← Pratt.pm_cast 64 v r p hsize, hpow]
  simp

/-- Check interval bounds alongside the primality witness. No shared-root
    recomputation and no growing list of already seen witness primes. -/
def checkRun (r : ℕ) (start : ℕ) : List (ℕ × ℕ) → Bool
  | [] => true
  | (p,v) :: ps => certOK r p v &&
      decide (start ^ 3 < p) && decide (p < (start + 1) ^ 3) &&
      checkRun r (start + 1) ps

theorem checkRun_sound {r start : ℕ} {ps : List (ℕ × ℕ)}
    (hr : r.Prime) (hc : checkRun r start ps = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) : Pratt.CubeAt n := by
  induction ps generalizing start with
  | nil => simp only [List.length_nil, Nat.add_zero] at hhi; omega
  | cons pv ps ih =>
    rcases pv with ⟨p,v⟩
    simp only [checkRun, Bool.and_eq_true, decide_eq_true_eq] at hc
    obtain ⟨⟨⟨hc, hpl⟩, hpu⟩, hrest⟩ := hc
    by_cases h : n = start
    · subst n
      exact ⟨p, certOK_sound hr hc, hpl, hpu⟩
    · have hb : n < (start + 1) + ps.length := by
        simp only [List.length_cons] at hhi
        omega
      exact ih hrest (by omega) hb

def knownPrimeOK (r : ℕ) (certs : List Pratt.Cert) : Bool :=
  match Pratt.foldCheck [2] certs with
  | none => false
  | some known => known.contains r

theorem knownPrimeOK_sound {r : ℕ} {certs : List Pratt.Cert}
    (h : knownPrimeOK r certs = true) : r.Prime := by
  unfold knownPrimeOK at h
  cases he : Pratt.foldCheck [2] certs with
  | none => simp [he] at h
  | some known =>
    simp only [he] at h
    exact Pratt.foldCheck_sound (fun q hq =>
      List.mem_singleton.mp hq ▸ Nat.prime_two) he r (List.contains_iff_mem.mp h)

/-- A fallback witness uses the existing Lucas list only when no shared-order
    witness was generated. The chosen prime and both strict bounds are checked. -/
def checkHybrid (r : ℕ) (known : List ℕ) (start : ℕ) : List (ℕ × Option ℕ) → Bool
  | [] => true
  | (p, ov) :: ps =>
      (match ov with | none => known.contains p | some v => certOK r p v) &&
      decide (start ^ 3 < p) && decide (p < (start + 1) ^ 3) &&
      checkHybrid r known (start + 1) ps

theorem checkHybrid_sound {r start : ℕ} {known : List ℕ} {ps : List (ℕ × Option ℕ)}
    (hr : r.Prime) (hknown : ∀ p ∈ known, p.Prime)
    (hc : checkHybrid r known start ps = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) : Pratt.CubeAt n := by
  induction ps generalizing start with
  | nil => simp only [List.length_nil, Nat.add_zero] at hhi; omega
  | cons pv ps ih =>
    rcases pv with ⟨p,ov⟩
    simp only [checkHybrid, Bool.and_eq_true, decide_eq_true_eq] at hc
    obtain ⟨⟨⟨hc, hpl⟩, hpu⟩, hrest⟩ := hc
    by_cases h : n = start
    · subst n
      refine ⟨p, ?_, hpl, hpu⟩
      cases ov with
      | none => exact hknown p (List.contains_iff_mem.mp hc)
      | some v => exact certOK_sound hr hc
    · have hb : n < (start + 1) + ps.length := by
        simp only [List.length_cons] at hhi
        omega
      exact ih hrest (by omega) hb

def checkHybridBatch (r start : ℕ) (certs : List Pratt.Cert)
    (ps : List (ℕ × Option ℕ)) : Bool :=
  match Pratt.foldCheck [2] certs with
  | none => false
  | some known => checkHybrid r known start ps

theorem checkHybridBatch_sound {r start : ℕ} {certs : List Pratt.Cert}
    {ps : List (ℕ × Option ℕ)} (hr : r.Prime)
    (hc : checkHybridBatch r start certs ps = true)
    (n : ℕ) (hlo : start ≤ n) (hhi : n < start + ps.length) : Pratt.CubeAt n := by
  unfold checkHybridBatch at hc
  cases he : Pratt.foldCheck [2] certs with
  | none => simp [he] at hc
  | some known =>
    simp only [he] at hc
    exact checkHybrid_sound hr (Pratt.foldCheck_sound (fun q hq =>
      List.mem_singleton.mp hq ▸ Nat.prime_two) he) hc n hlo hhi

#print axioms checkHybridBatch_sound
#print axioms checkRun_sound
#print axioms knownPrimeOK_sound
end CubePrime.OneFactor
