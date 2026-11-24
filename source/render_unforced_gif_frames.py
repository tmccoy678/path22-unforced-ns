#!/usr/bin/env python3

from __future__ import annotations

import csv
import html
import math
import re
import sys
from pathlib import Path


def load_table(path: Path) -> dict[str, list[dict[str, float]]]:
    result: dict[str, list[dict[str, float]]] = {}
    with path.open(encoding="utf-8", newline="") as stream:
        for raw in csv.DictReader(stream, delimiter="\t"):
            row = {}
            for key, value in raw.items():
                if key == "case":
                    row[key] = value
                elif key == "trace_pass":
                    row[key] = 1.0 if value == "TRUE" else 0.0
                else:
                    row[key] = float(value)
            result.setdefault(str(row["case"]), []).append(row)  # type: ignore[arg-type]
    for rows in result.values():
        rows.sort(key=lambda row: float(row["time"]))
    return result


def lerp(a: float, b: float, q: float) -> float:
    return a + (b - a) * q


def interpolate(rows: list[dict[str, float]], time: float) -> dict[str, float]:
    if time <= rows[0]["time"]:
        return rows[0]
    if time >= rows[-1]["time"]:
        return rows[-1]
    for left, right in zip(rows, rows[1:]):
        if left["time"] <= time <= right["time"]:
            q = (time - left["time"]) / (right["time"] - left["time"])
            return {
                key: (left[key] if key == "case" else lerp(float(left[key]), float(right[key]), q))
                for key in left
            }
    raise RuntimeError("time outside table")


def polyline(rows: list[dict[str, float]], key: str, x: float, y: float, width: float, height: float, low: float, high: float) -> str:
    points = []
    for row in rows:
        px = x + row["time"] / 0.5 * width
        py = y + (high - row[key]) / (high - low) * height
        points.append(f"{px:.2f},{py:.2f}")
    return " ".join(points)


def status_for(time: float) -> str:
    if time < 0.025:
        return "release · the score becomes a body"
    if time < 0.075:
        return "concentration · local speed rises while global energy falls"
    if time < 0.15:
        return "inversion · fixed-whisker retention reaches zero"
    if time < 0.275:
        return "continued inversion · the smooth energetic body remains"
    if time < 0.425:
        return "weak return · orientation becomes positive again"
    return "release · the carrier leaves the fixed listening geometry"


def frame_overlay(
    music: dict[str, float],
    control: dict[str, float],
    all_music: list[dict[str, float]],
    all_control: list[dict[str, float]],
) -> str:
    time = music["time"]
    energy = music["energy_fraction"]
    speed = music["max_speed"]
    cosine = music["shape_cosine"]
    amplitude = music["amplitude_ratio"]
    retention = music["retention"]
    map_darkness = 0.42 * (1.0 - energy)
    border_glow = 0.10 + 0.42 * min(1.0, speed / 140.0)

    panel_x = 1825
    graph_x = 1880
    graph_w = 520
    energy_y = 680
    cosine_y = 850
    graph_h = 92
    cursor_x = graph_x + time / 0.5 * graph_w

    wave_points = []
    wave_amp = 9 + 96 * math.sqrt(max(0.0, amplitude))
    phase = 0.0 if cosine >= 0 else math.pi
    for index in range(161):
        q = index / 160
        x = graph_x + q * graph_w
        y = 465 + wave_amp * math.sin(math.tau * 5 * q + phase)
        wave_points.append(f"{x:.2f},{y:.2f}")

    music_energy = polyline(all_music, "energy_fraction", graph_x, energy_y, graph_w, graph_h, 0, 1)
    control_energy = polyline(all_control, "energy_fraction", graph_x, energy_y, graph_w, graph_h, 0, 1)
    music_cosine = polyline(all_music, "shape_cosine", graph_x, cosine_y, graph_w, graph_h, -1, 1)
    control_cosine = polyline(all_control, "shape_cosine", graph_x, cosine_y, graph_w, graph_h, -1, 1)

    return f"""
<g id="unforced-panel">
  <rect x="105" y="175" width="1640" height="840" rx="18" fill="#02050a" opacity="{map_darkness:.4f}"/>
  <rect x="105" y="175" width="1640" height="840" rx="18" fill="none" stroke="#36e2ff" stroke-width="7" opacity="{border_glow:.4f}" filter="url(#glow)"/>
  <line x1="1795" y1="38" x2="1795" y2="1080" stroke="#30475a" stroke-width="2"/>
  <text x="{panel_x}" y="62" fill="#f4f7fb" font-family="Helvetica,Arial,sans-serif" font-size="32" font-weight="700">UNFORCED REALIZATION</text>
  <text x="{panel_x}" y="102" fill="#91a9bb" font-family="Menlo,monospace" font-size="18">t = {time:.3f}    ν = 0.01    f = 0</text>

  <text x="{panel_x}" y="156" fill="#77e9ff" font-family="Times New Roman,serif" font-size="23">A₂₂(x) = Gσ * ∫ q(s)T(s)δ(x−X(s)) ds</text>
  <text x="{panel_x}" y="197" fill="#77e9ff" font-family="Times New Roman,serif" font-size="24">u₀ = ∇ × A₂₂</text>
  <text x="{panel_x}" y="250" fill="#ffce73" font-family="Times New Roman,serif" font-size="24">∂ₜu = P[u × (∇ × u)] + νΔu</text>
  <text x="{panel_x}" y="291" fill="#ffce73" font-family="Times New Roman,serif" font-size="24">∇·u = 0   ·   f = 0   ·   E(0) = 1</text>

  <text x="{panel_x}" y="348" fill="#d5dee6" font-family="Helvetica,Arial,sans-serif" font-size="18">{html.escape(status_for(time))}</text>
  <text x="{panel_x}" y="386" fill="#7f97aa" font-family="Helvetica,Arial,sans-serif" font-size="16">fixed-whisker chord · amplitude × orientation</text>
  <polyline points="{' '.join(wave_points)}" fill="none" stroke="{'#54e8ff' if cosine >= 0 else '#bd8cff'}" stroke-width="4" opacity="{0.35 + 0.65 * min(1.0, math.sqrt(max(0.0, amplitude)) * 3):.3f}"/>
  <line x1="{graph_x}" y1="465" x2="{graph_x+graph_w}" y2="465" stroke="#41586b" stroke-width="1"/>

  <text x="{panel_x}" y="590" fill="#f0f4f8" font-family="Menlo,monospace" font-size="18">E/E₀ {energy:.6f}   max|u| {speed:.3f}</text>
  <text x="{panel_x}" y="622" fill="#f0f4f8" font-family="Menlo,monospace" font-size="18">C {cosine:+.6f}   A {amplitude:.6f}   R {retention:.6f}</text>

  <text x="{graph_x}" y="{energy_y-14}" fill="#91a9bb" font-family="Helvetica,Arial,sans-serif" font-size="15">resolved energy · music / phase-erased</text>
  <rect x="{graph_x}" y="{energy_y}" width="{graph_w}" height="{graph_h}" fill="#09131c" stroke="#2d4355"/>
  <polyline points="{control_energy}" fill="none" stroke="#778b9c" stroke-width="3"/>
  <polyline points="{music_energy}" fill="none" stroke="#ffcb5c" stroke-width="4"/>
  <line x1="{cursor_x:.2f}" y1="{energy_y}" x2="{cursor_x:.2f}" y2="{energy_y+graph_h}" stroke="#ffffff" stroke-width="2" opacity="0.8"/>

  <text x="{graph_x}" y="{cosine_y-14}" fill="#91a9bb" font-family="Helvetica,Arial,sans-serif" font-size="15">orientation cosine · zero line is observational, not annihilation</text>
  <rect x="{graph_x}" y="{cosine_y}" width="{graph_w}" height="{graph_h}" fill="#09131c" stroke="#2d4355"/>
  <line x1="{graph_x}" y1="{cosine_y+graph_h/2}" x2="{graph_x+graph_w}" y2="{cosine_y+graph_h/2}" stroke="#597082" stroke-width="1"/>
  <polyline points="{control_cosine}" fill="none" stroke="#778b9c" stroke-width="3"/>
  <polyline points="{music_cosine}" fill="none" stroke="#54e8ff" stroke-width="4"/>
  <line x1="{cursor_x:.2f}" y1="{cosine_y}" x2="{cursor_x:.2f}" y2="{cosine_y+graph_h}" stroke="#ffffff" stroke-width="2" opacity="0.8"/>

  <text x="{panel_x}" y="974" fill="#74e8ff" font-family="Menlo,monospace" font-size="17">normalized divergence ≈ {music['normalized_divergence']:.3e}</text>
  <text x="{panel_x}" y="1005" fill="#8fa5b5" font-family="Helvetica,Arial,sans-serif" font-size="16">visualization of Lean-bound metrics · no tracked center</text>
  <text x="{panel_x}" y="1033" fill="#8fa5b5" font-family="Helvetica,Arial,sans-serif" font-size="16">solid path = measured geometry · fading waves = inference</text>
  <text x="{panel_x}" y="1083" fill="#d8e1e8" font-family="Times New Roman,serif" font-size="20" font-style="italic">The body leaves the listener without leaving the field.</text>
</g>
"""


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("usage: render_unforced_gif_frames.py BASE.svg EVOLUTION.tsv OUT_DIR")
    base = Path(sys.argv[1]).read_text(encoding="utf-8")
    base = re.sub(
        r'<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="1120" viewBox="0 0 1800 1120">',
        '<svg xmlns="http://www.w3.org/2000/svg" width="1800" height="806" viewBox="0 0 2500 1120">',
        base,
        count=1,
    )
    if not base.endswith("</svg>"):
        raise RuntimeError("unexpected base SVG")
    base = base[:-6]
    table = load_table(Path(sys.argv[2]))
    music_rows = table["path22_music"]
    control_rows = table["phase_erased_control"]
    times = [0.0] * 5
    checkpoints = [row["time"] for row in music_rows]
    for start, end in zip(checkpoints, checkpoints[1:]):
        times.extend(lerp(start, end, step / 8) for step in range(1, 9))
    times.extend([0.5] * 8)
    out = Path(sys.argv[3])
    out.mkdir(parents=True, exist_ok=True)
    for index, time in enumerate(times):
        music = interpolate(music_rows, time)
        control = interpolate(control_rows, time)
        frame = base + frame_overlay(music, control, music_rows, control_rows) + "</svg>\n"
        (out / f"frame-{index:03d}.svg").write_text(frame, encoding="utf-8")
    print(f"frames={len(times)}")


if __name__ == "__main__":
    main()

