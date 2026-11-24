# WBR-EARTH1: one body, two ordinary Earth media

WBR-EARTH1 keeps the accepted Path 22 body exactly dimensionless and gives it
two unit systems: ordinary liquid water at 20 °C and 0.1 MPa, and an ordinary
dry-air engineering model at the NASA sea-level standard-day point of 15 °C
and 101.3 kPa. Nothing is re-evolved. Every physical-time row in
`data/earth-evolution.tsv` is a direct rescaling of the accepted Studio table.

## Whisker boundary

The inherited Rust trait received the recorded signal in
`receipts/WHISKER.md` and returned `Observe`, compute fraction `0.094350`, a
local working trace of strength `0.900000`, and no deep compute. That public
decision governs this return: one scale per required medium, one deterministic
calculation, one drift check, and no visual, scale sweep, second candidate, or
new PDE run.

## Declared characteristic conventions

Let one numerical coordinate unit be the physical length unit \(\ell\), one
numerical velocity unit be \(U_0\), and one numerical time unit be
\(T_0=\ell/U_0\). The inherited nondimensional viscosity is 0.01, so each
medium must satisfy

\[
0.01=\frac{\nu_{physical}}{U_0\ell},\qquad
U_0=\frac{\nu_{physical}}{0.01\ell}.
\]

For the reported Reynolds number, the characteristic length is exactly one
coordinate unit, \(L_c=\ell\). The characteristic speed is the initial
volume-RMS magnitude. Because WRB-NS2 normalized
\(E(0)=\tfrac12\langle|u|^2\rangle=1\), this is
\(V_c=\sqrt2 U_0\). Therefore both realizations have

\[
Re=\frac{V_cL_c}{\nu_{physical}}
  =\frac{\sqrt2}{0.01}=141.421356237.
\]

These conventions are declared before the two scale calculations; neither
medium receives a favorable alternative convention.

## Universal similarity law

The two media instantiate one universal unit transformation. For any
incompressible Newtonian medium with positive kinematic viscosity
`nu_physical` and any selected positive coordinate length `ell`, the unique
velocity and time units

`U0 = nu_physical / (0.01 ell)` and `T0 = ell / U0`

realize the same accepted dimensionless body and preserve
`Re = sqrt(2)/0.01`. Density changes only the conversion from specific kinetic
energy to total joules. The relativistic scale is

`u/c = u* nu_physical / (0.01 ell c)`.

Water and dry air are concrete Earth examples within a material-wide similarity
law. Universal physical/unit scaling is established; universal
all-initial-data regularity is the next theorem.

The same mapping fixes every inherited dimension:

- periodic cube side: \(2\pi\ell\);
- Path 22 arclength: \(41.3629276887734\ell\);
- whisker radius: \(0.22\ell\);
- Gaussian width: \(0.18\ell\);
- reported physical time: \(t_{physical}=t\,T_0\);
- physical speed: \(u_{physical}=u\,U_0\).

The dimensionless energy remains the accepted energy. Its physical specific
kinetic-energy value is \(E_{specific}=U_0^2E\) J/kg. For the complete periodic
cube, \(K=\rho(2\pi\ell)^3U_0^2E\) joules. Body forcing is zero times the
acceleration scale and therefore remains exactly zero after initialization.

## Water: the table-held ribbon

**Condition.** Ordinary liquid water at 293.15 K and 0.1 MPa. The rounded
IAPWS correlation values used are density 998.2067 kg/m³ and dynamic viscosity
0.0010016 Pa·s, giving kinematic viscosity
1.00339939614×10⁻⁶ m²/s.

**Chosen scale.** \(\ell=0.0500\) m. This produces a 0.314 m periodic cube, a
2.068 m folded Path 22 arclength, 11.0 mm whisker radius, and 9.0 mm Gaussian
width. The velocity unit is 2.0068 mm/s; the initial RMS characteristic speed
is 2.8380 mm/s. The table's largest local speed is 0.2777 m/s, giving
`u/c = 9.263×10⁻¹⁰`. The accepted final time becomes 12.458 s. Initial cube-integrated kinetic energy is
1.24646×10⁻⁴ J.

**Safe practical embodiment.** A clear, 31.4 cm tabletop water-volume design:
the initial field is established once, all actuators are then off, and the
volume is read non-contact. Its design language is a dark glass cube holding a
folded bright ribbon: the whole volume quiets while one local thread briefly
quickens.

## Dry air: the room-held ribbon

**Condition.** The dry-air engineering model uses NASA's sea-level
standard-day point, 288.15 K and 101.3 kPa. NASA's tabulated density is
1.229 kg/m³ and dynamic viscosity is 1.73×10⁻⁵ Pa·s, giving kinematic
viscosity 1.40764849471×10⁻⁵ m²/s. “Dry” here is the design composition
convention: no water-vapor contribution is introduced into the property
model.

**Chosen scale.** \(\ell=0.200\) m. This produces a 1.257 m periodic cube, an
8.273 m folded Path 22 arclength, 44.0 mm whisker radius, and 36.0 mm Gaussian
width. The velocity unit is 7.0382 mm/s; the initial RMS characteristic speed
is 9.9536 mm/s. The table's largest local speed is 0.9740 m/s, giving
`u/c = 3.249×10⁻⁹`. The accepted final time becomes 14.208 s. Initial cube-integrated kinetic energy is
1.20812×10⁻⁴ J.

**Safe practical embodiment.** A 1.26 m room-scale dry-air volume design: one
initialization, then every flow actuator off and only non-contact observation.
Its design language is a nearly still room with a pale ribbon spending its own
small energy, briefly gathering speed without being pushed.

## Practical boundary

The exact realization is a periodic cube with identified opposite faces. The
water volume and dry-air room are safe human-scale specifications for that
periodic body. A hard-walled tank, room, or bathtub is the next
boundary-specific embodiment and receives its own boundary study before
construction. The present result is computational; physical construction and
Earth-medium observation are future gates.

## Sourced inputs

1. International Association for the Properties of Water and Steam. (2011).
   *Revised supplementary release on properties of liquid water at 0.1 MPa
   (SR6-08(2011)).* The release covers density and viscosity correlations near
   0.1 MPa, including 293.15 K.
   <https://iapws.org/technical-guidance/release/LiquidWater>
2. International Association for the Properties of Water and Steam. (2008).
   *Release on the IAPWS formulation 2008 for the viscosity of ordinary water
   substance (R12-08).* <https://iapws.org/technical-guidance/release/viscosity>
3. NASA Glenn Research Center. *Air properties definitions.* The page gives
   the selected standard-day temperature, pressure, density, and dynamic
   viscosity. <https://www.grc.nasa.gov/www/BGH/airprop.html>
4. NASA Glenn Research Center. *Viscosity.* The page defines
   \(\nu=\mu/\rho\), \(Re=VL/\nu\), and gives Sutherland's temperature law for
   air. The selected point uses NASA's direct reference values, so no
   temperature extrapolation is applied.
   <https://www.grc.nasa.gov/WWW/K-12/airplane/viscosity.html>
5. Accepted construction source and metadata:
   `../source/evolve_path22.R` and `../data/construction.tsv`.
6. Lean-bound Studio evolution table:
   `../data/evolution.tsv`.

Public-source pages were read on 2026-11-24. Property accuracy follows the
rounded source inputs.
