#!/usr/bin/env python3
"""Translate the accepted WRB-NS2 table into two physical unit systems.

This script performs similarity scaling only.  It never constructs or evolves
a velocity field.
"""

from __future__ import annotations

import argparse
import csv
import io
import math
from pathlib import Path


HERE = Path(__file__).resolve().parent
EVOLUTION = HERE.parent / "data" / "evolution.tsv"
CONSTRUCTION = HERE.parent / "data" / "construction.tsv"
SUMMARY_OUT = HERE / "earth-realizations.tsv"
EVOLUTION_OUT = HERE / "earth-evolution.tsv"

IAPWS_WATER = "https://iapws.org/technical-guidance/release/LiquidWater"
NASA_AIR = "https://www.grc.nasa.gov/www/BGH/airprop.html"
SPEED_OF_LIGHT_M_S = 299_792_458.0

# One selected scale per medium.  The water values are the rounded IAPWS
# liquid-water correlations at 293.15 K and 0.1 MPa.  The air values are the
# sea-level standard-day values printed by NASA Glenn at 288.15 K.
MEDIA = (
    {
        "medium": "ordinary liquid water",
        "temperature_K": 293.15,
        "pressure_Pa": 100_000.0,
        "density_kg_m3": 998.2067,
        "dynamic_viscosity_Pa_s": 1.0016e-3,
        "length_unit_m": 0.05,
        "property_source": IAPWS_WATER,
        "embodiment": "31.4 cm periodic-cube tabletop water-volume design",
    },
    {
        "medium": "standard dry air",
        "temperature_K": 288.15,
        "pressure_Pa": 101_300.0,
        "density_kg_m3": 1.229,
        "dynamic_viscosity_Pa_s": 1.73e-5,
        "length_unit_m": 0.20,
        "property_source": NASA_AIR,
        "embodiment": "1.26 m periodic-cube room-scale dry-air design",
    },
)


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def construction_values() -> dict[str, str]:
    return {row["metric"]: row["value"] for row in read_tsv(CONSTRUCTION)}


def fmt(value: object) -> str:
    if isinstance(value, float):
        return f"{value:.12g}"
    return str(value)


def tsv_text(rows: list[dict[str, object]], fields: list[str]) -> str:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    for row in rows:
        writer.writerow({field: fmt(row[field]) for field in fields})
    return stream.getvalue()


def calculate() -> tuple[str, str]:
    construction = construction_values()
    evolution = read_tsv(EVOLUTION)
    music = [row for row in evolution if row["case"] == "path22_music"]
    if [float(row["time"]) for row in music] != [0, 0.05, 0.1, 0.2, 0.35, 0.5]:
        raise ValueError("unexpected accepted Studio output times")

    nu_dimensionless = float(construction["viscosity"])
    if nu_dimensionless != 0.01 or construction["body_force"] != "identically_zero":
        raise ValueError("accepted viscosity or forcing changed")
    path_length = float(construction["transformed_arclength"])
    whisker_radius = float(construction["whisker_radius"])
    gaussian_sigma = float(construction["gaussian_sigma"])
    characteristic_speed_dimensionless = math.sqrt(2.0)  # sqrt(mean |u|^2)
    target_reynolds = characteristic_speed_dimensionless / nu_dimensionless

    summary_rows: list[dict[str, object]] = []
    evolution_rows: list[dict[str, object]] = []
    for medium in MEDIA:
        rho = float(medium["density_kg_m3"])
        mu = float(medium["dynamic_viscosity_Pa_s"])
        nu = mu / rho
        length_unit = float(medium["length_unit_m"])
        velocity_unit = nu / (nu_dimensionless * length_unit)
        time_unit = length_unit / velocity_unit
        characteristic_speed = characteristic_speed_dimensionless * velocity_unit
        reynolds = characteristic_speed * length_unit / nu
        domain_side = 2.0 * math.pi * length_unit
        volume = domain_side**3
        initial_specific_ke = velocity_unit**2  # dimensionless E(0) = 1
        initial_total_ke = rho * volume * initial_specific_ke
        peak_speeds = [float(row["max_speed"]) * velocity_unit for row in music]

        if not math.isclose(reynolds, target_reynolds, rel_tol=0.0, abs_tol=1e-12):
            raise ValueError("Reynolds similarity failed")

        summary_rows.append(
            {
                "medium": medium["medium"],
                "temperature_K": medium["temperature_K"],
                "pressure_Pa": medium["pressure_Pa"],
                "density_kg_m3": rho,
                "dynamic_viscosity_Pa_s": mu,
                "kinematic_viscosity_m2_s": nu,
                "property_source": medium["property_source"],
                "length_unit_m": length_unit,
                "velocity_unit_m_s": velocity_unit,
                "time_unit_s": time_unit,
                "characteristic_length_m": length_unit,
                "characteristic_speed_rms_m_s": characteristic_speed,
                "characteristic_speed_over_c": characteristic_speed / SPEED_OF_LIGHT_M_S,
                "reynolds_number": reynolds,
                "domain_side_m": domain_side,
                "path_arclength_m": path_length * length_unit,
                "whisker_radius_m": whisker_radius * length_unit,
                "gaussian_sigma_m": gaussian_sigma * length_unit,
                "final_duration_s": 0.5 * time_unit,
                "initial_peak_speed_m_s": peak_speeds[0],
                "table_peak_speed_m_s": max(peak_speeds),
                "table_peak_speed_over_c": max(peak_speeds) / SPEED_OF_LIGHT_M_S,
                "initial_specific_ke_J_kg": initial_specific_ke,
                "initial_total_ke_J": initial_total_ke,
                "body_force_m_s2": 0.0,
                "embodiment": medium["embodiment"],
            }
        )

        for row in music:
            energy = float(row["energy"])
            evolution_rows.append(
                {
                    "medium": medium["medium"],
                    "dimensionless_time": float(row["time"]),
                    "physical_time_s": float(row["time"]) * time_unit,
                    "energy_fraction": float(row["energy_fraction"]),
                    "specific_ke_J_kg": energy * initial_specific_ke,
                    "total_ke_J": energy * initial_total_ke,
                    "max_speed_m_s": float(row["max_speed"]) * velocity_unit,
                    "shape_cosine": float(row["shape_cosine"]),
                    "amplitude_ratio": float(row["amplitude_ratio"]),
                    "retention": float(row["retention"]),
                    "trace_pass": row["trace_pass"],
                }
            )

    summary_fields = list(summary_rows[0])
    evolution_fields = list(evolution_rows[0])
    return tsv_text(summary_rows, summary_fields), tsv_text(evolution_rows, evolution_fields)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="refuse output drift")
    args = parser.parse_args()
    summary, evolution = calculate()
    outputs = ((SUMMARY_OUT, summary), (EVOLUTION_OUT, evolution))
    if args.check:
        for path, expected in outputs:
            if not path.is_file() or path.read_text(encoding="utf-8") != expected:
                raise SystemExit(f"drift: {path}")
        print("earth realization tables: OK")
        return
    for path, contents in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
    print(f"wrote {SUMMARY_OUT}")
    print(f"wrote {EVOLUTION_OUT}")


if __name__ == "__main__":
    main()
