import SchoenfeldTightNumerics

namespace CubeSchoenfeldTight
open Real

theorem theta_increase (psi theta : ℝ → ℝ) {pi m : ℝ}
    (hm : 512 ≤ m) (hp : 3 ≤ pi)
    (hs : ∀ x : ℝ, (366 / 5 : ℝ) ≤ x →
      |psi x - x| < sqrt x * (log x)^2 / (8 * pi))
    (ht : ∀ x : ℝ, theta x ≤ psi x)
    (htail : ∀ x : ℝ, 1 ≤ x → psi x - theta x ≤ 2 * sqrt x * log x) :
    theta ((m - 1)^3) < theta (m^3) := by
  have mp : (0 : ℝ) ≤ m := by linarith
  have mm : (0 : ℝ) ≤ m - 1 := by linarith
  let a := (m - 1)^3
  let b := m^3
  have ha : (366 / 5 : ℝ) ≤ a := by
    calc
      (366 / 5 : ℝ) ≤ 5^3 := by norm_num
      _ ≤ a := pow_le_pow_left₀ (by norm_num) (by linarith) 3
  have hab : a ≤ b := pow_le_pow_left₀ mm (by linarith) 3
  have hb : (366 / 5 : ℝ) ≤ b := ha.trans hab
  have ha0 : 0 < a := by linarith
  have hb1 : 1 ≤ b := by linarith
  have halog : 0 ≤ log a := log_nonneg (by linarith)
  have hlb : log b = 3 * log m := by
    dsimp [b]
    rw [log_pow]
    norm_num
  have hsquare : (log a)^2 ≤ (log b)^2 :=
    pow_le_pow_left₀ halog (log_le_log ha0 hab) 2
  have hprod : sqrt a * (log a)^2 ≤ sqrt b * (log b)^2 :=
    mul_le_mul (sqrt_le_sqrt hab) hsquare (sq_nonneg _) (sqrt_nonneg b)
  have ea := (abs_lt.mp (hs a ha)).2
  have eb := (abs_lt.mp (hs b hb)).1
  have herror : sqrt b * (log b)^2 / (8*pi) ≤ (3/8) * sqrt b * (log m)^2 := by
    calc
      _ ≤ sqrt b * (log b)^2 / 24 :=
        div_le_div_of_nonneg_left (by positivity) (by norm_num) (by linarith)
      _ = _ := by rw [hlb]; ring
  have herror_a : sqrt a * (log a)^2 / (8*pi) ≤ (3/8) * sqrt b * (log m)^2 :=
    (div_le_div_of_nonneg_right hprod (by linarith)).trans herror
  have htail_b := htail b hb1
  rw [hlb] at htail_b
  have hbudget := budget hm
  change (3/4) * sqrt b * (log m)^2 + 6 * sqrt b * log m < (299/100)*m^2 at hbudget
  have hlinear : 3*m ≤ (3/512)*m^2 := by
    nlinarith [mul_nonneg mp (show 0 ≤ m - 512 by linarith)]
  have hgap : (299/100)*m^2 ≤ b - a := by
    dsimp [a, b]
    nlinarith [sq_nonneg m]
  linarith [ht a]

#print axioms theta_increase
end CubeSchoenfeldTight
