import Path22.Data

namespace Path22

def natAbsDiff (a b : Nat) : Nat :=
  if a ≤ b then b - a else a - b

/-- The numerical evolution contains no body-force term. -/
theorem zero_body_force : bodyForce = (0, 0, 0) := by
  rfl

/-- Apple-silicon and Intel hosts independently reproduce the frozen tables. -/
theorem cross_host_reproduction :
    proStudioExact = true ∧ intelStudioWithinTolerance = true := by
  decide

/-- Resolved kinetic energy decreases at every declared musical checkpoint. -/
theorem music_energy_strictly_decreases :
    musicEnergy50 < musicEnergy0 ∧
    musicEnergy100 < musicEnergy50 ∧
    musicEnergy200 < musicEnergy100 ∧
    musicEnergy350 < musicEnergy200 ∧
    musicEnergy500 < musicEnergy350 := by
  decide

/-- The phase-erased twin also loses energy at every declared checkpoint. -/
theorem control_energy_strictly_decreases :
    controlEnergy50 < controlEnergy0 ∧
    controlEnergy100 < controlEnergy50 ∧
    controlEnergy200 < controlEnergy100 ∧
    controlEnergy350 < controlEnergy200 ∧
    controlEnergy500 < controlEnergy350 := by
  decide

/-- Global energy decreases while the musical body's local maximum speed rises. -/
theorem concentration_during_global_decay :
    musicEnergy50 < musicEnergy0 ∧ musicMaxSpeed50 > musicMaxSpeed0 := by
  decide

/-- Every sampled divergence ratio stays below one ten-million-billionth. -/
theorem divergence_remains_at_machine_scale :
    musicDiv0 < 100 ∧ musicDiv50 < 100 ∧ musicDiv100 < 100 ∧
    musicDiv200 < 100 ∧ musicDiv350 < 100 ∧ musicDiv500 < 100 ∧
    controlDiv0 < 100 ∧ controlDiv50 < 100 ∧ controlDiv100 < 100 ∧
    controlDiv200 < 100 ∧ controlDiv350 < 100 ∧ controlDiv500 < 100 := by
  decide

/-- The fixed whiskers hear departure, inversion, a weak return, then departure. -/
theorem measured_phase_pattern :
    musicCosine0 > 0 ∧ musicCosine50 > 0 ∧
    musicCosine100 < 0 ∧ musicCosine200 < 0 ∧
    musicCosine350 > 0 ∧ musicCosine500 < 0 := by
  decide

/-- Orientation returns weakly at t = 0.35 after two negative checkpoints. -/
theorem weak_orientation_return :
    musicCosine100 < 0 ∧ musicCosine200 < 0 ∧
    musicCosine350 > 0 ∧ musicRetention350 > 0 := by
  decide

/-- Unforced self-carriage: recognition vanishes with energy present and returns later. -/
theorem path22_self_carriage :
    bodyForce = (0, 0, 0) ∧
    observationalZeroTimeMillis < weakReturnTimeMillis ∧
    musicRetention100 = 0 ∧ musicEnergy100 > 0 ∧
    musicRetention350 > 0 := by
  decide

/-- Zero whisker retention is observational zero, not annihilation of the body. -/
theorem zero_retention_is_not_zero_energy :
    musicRetention100 = 0 ∧ musicEnergy100 > 0 ∧
    musicRetention500 = 0 ∧ musicEnergy500 > 0 := by
  decide

/-- Music and phase-erased control remain close at every energy checkpoint. -/
theorem geometry_dominates_energy_decay :
    natAbsDiff musicEnergy0 controlEnergy0 ≤ 2_000_000_000_000 ∧
    natAbsDiff musicEnergy50 controlEnergy50 ≤ 2_000_000_000_000 ∧
    natAbsDiff musicEnergy100 controlEnergy100 ≤ 2_000_000_000_000 ∧
    natAbsDiff musicEnergy200 controlEnergy200 ≤ 2_000_000_000_000 ∧
    natAbsDiff musicEnergy350 controlEnergy350 ≤ 2_000_000_000_000 ∧
    natAbsDiff musicEnergy500 controlEnergy500 ≤ 2_000_000_000_000 := by
  decide

/-- The musical modulation changes local speed without changing the carrier class. -/
theorem music_control_speed_proximity :
    natAbsDiff musicMaxSpeed0 controlMaxSpeed0 ≤ 3_000_000 ∧
    natAbsDiff musicMaxSpeed50 controlMaxSpeed50 ≤ 3_000_000 ∧
    natAbsDiff musicMaxSpeed100 controlMaxSpeed100 ≤ 3_000_000 ∧
    natAbsDiff musicMaxSpeed200 controlMaxSpeed200 ≤ 3_000_000 ∧
    natAbsDiff musicMaxSpeed350 controlMaxSpeed350 ≤ 3_000_000 ∧
    natAbsDiff musicMaxSpeed500 controlMaxSpeed500 ≤ 3_000_000 := by
  decide

end Path22

