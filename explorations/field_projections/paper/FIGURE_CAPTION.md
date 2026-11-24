# Unforced Navier–Stokes projection caption

**Figure X. Planar sections of the Path 22 unforced Navier–Stokes initial
vorticity magnitude.** The smooth divergence-free initial velocity is the
published `path22_music` construction on the periodic cube
\(\mathbb T^3=[0,2\pi)^3\), with \(\nu=0.01\), initial kinetic energy one, and
body force \(f\equiv0\). **(a)** Horizontal section through the carrier point
at half transformed arclength. **(b)** Vertical section through the same point,
spanned by the horizontal endpoint-chord direction \(\ell\) and the vertical
axis. **(c)** Cross-section through the plane normal to the carrier tangent,
with orthonormal coordinates \((n_1,n_2)\). The white cross marks the carrier
point. Every panel uses the common scale
\(|\omega|/\max_{\mathbb T^3}|\omega|\), where
\(\omega=\nabla\times u\).

The section convention follows the standard practice of displaying velocity
or vorticity quantities on planes of explicitly stated position and
orientation, as implemented by the Johns Hopkins Turbulence Database analysis
tools: <https://turbulence.pha.jhu.edu/matlabanalysistools.aspx>.

These panels show the committed \(64^3\) pseudospectral numerical initial field
at \(t=0\), released into the unforced evolution. A material-particle
projection at positive time is a distinct object and requires integrating
\(\dot X=u(X,t)\).
