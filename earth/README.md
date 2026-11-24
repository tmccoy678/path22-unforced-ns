# Physical similarity map

The accepted Path 22 body is dimensionless. This directory maps it into two
ordinary incompressible Newtonian media without another PDE solve: liquid
water at 20 °C and 0.1 MPa, and a dry-air engineering model at the NASA
sea-level standard-day point.

## Similarity law

Let one numerical coordinate unit be the physical length \(\ell\), one
numerical velocity unit be \(U_0\), and one numerical time unit be
\(T_0=\ell/U_0\). The inherited nondimensional viscosity is 0.01, so

\[
U_0=\frac{\nu_{physical}}{0.01\ell},
\qquad
T_0=\frac{\ell}{U_0}.
\]

The initial dimensionless energy satisfies
\(E(0)=\tfrac12\langle|u|^2\rangle=1\). With characteristic length
\(L_c=\ell\) and RMS speed \(V_c=\sqrt2U_0\), every realization has

\[
Re=\frac{V_cL_c}{\nu_{physical}}
=\frac{\sqrt2}{0.01}=141.421356237.
\]

Density affects total energy but not the dimensionless evolution. Body forcing
remains exactly zero after initialization.

## Two sourced realizations

| Quantity | Water | Dry air |
|---|---:|---:|
| Thermodynamic point | 293.15 K, 0.1 MPa | 288.15 K, 101.3 kPa |
| Density | 998.2067 kg/m³ | 1.229 kg/m³ |
| Dynamic viscosity | 0.0010016 Pa·s | \(1.73\times10^{-5}\) Pa·s |
| Kinematic viscosity | \(1.00339939614\times10^{-6}\) m²/s | \(1.40764849471\times10^{-5}\) m²/s |
| Selected \(\ell\) | 0.0500 m | 0.200 m |
| Periodic cube side | 0.314 m | 1.257 m |
| Path 22 arclength | 2.068 m | 8.273 m |
| Gaussian width | 9.0 mm | 36.0 mm |
| Annular-probe radius | 11.0 mm | 44.0 mm |
| Velocity unit \(U_0\) | 2.0068 mm/s | 7.0382 mm/s |
| Initial RMS speed | 2.8380 mm/s | 9.9536 mm/s |
| Maximum recorded local speed | 0.2777 m/s | 0.9740 m/s |
| Maximum recorded \(u/c\) | \(9.263\times10^{-10}\) | \(3.249\times10^{-9}\) |
| Final reported physical time | 12.458 s | 14.208 s |
| Initial cube-integrated kinetic energy | \(1.24646\times10^{-4}\) J | \(1.20812\times10^{-4}\) J |

The deterministic calculations are committed in `calculate.py`,
`earth-realizations.tsv`, and `earth-evolution.tsv`.

## Geometry and energy conversion

The similarity map gives:

- periodic cube side \(2\pi\ell\);
- Path 22 arclength \(41.3629276887734\ell\);
- annular-probe radius \(0.22\ell\);
- Gaussian width \(0.18\ell\);
- physical time \(t_{physical}=tT_0\);
- physical speed \(u_{physical}=uU_0\).

Specific kinetic energy is \(E_{specific}=U_0^2E\) J/kg. For the complete
periodic cube,

\[
K=\rho(2\pi\ell)^3U_0^2E.
\]

## Physical boundary

The numerical realization is a periodic cube with identified opposite faces.
A hard-walled tank or room is a different boundary-value problem and requires
its own boundary study before physical construction.

## Sources

1. International Association for the Properties of Water and Steam. *Revised
   supplementary release on properties of liquid water at 0.1 MPa
   (SR6-08(2011)).* <https://iapws.org/technical-guidance/release/LiquidWater>
2. International Association for the Properties of Water and Steam. *Release
   on the IAPWS formulation 2008 for the viscosity of ordinary water substance
   (R12-08).* <https://iapws.org/technical-guidance/release/viscosity>
3. NASA Glenn Research Center. *Air properties definitions.*
   <https://www.grc.nasa.gov/www/BGH/airprop.html>
4. NASA Glenn Research Center. *Viscosity.*
   <https://www.grc.nasa.gov/WWW/K-12/airplane/viscosity.html>
5. Construction metadata: `../data/construction.tsv`.
6. Lean-bound evolution table: `../data/evolution.tsv`.

Public source pages were read on 2026-11-24. Property accuracy follows the
rounded source inputs.
