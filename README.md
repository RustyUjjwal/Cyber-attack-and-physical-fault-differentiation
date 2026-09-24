# Simulating Power Grid Cyber-Attacks: Utilizing V-I Correlation to Differentiate FDI Attacks from Physical Faults

![MATLAB](https://img.shields.io/badge/MATLAB-R2023a+-blue.svg)
![Simulink](https://img.shields.io/badge/Simulink-Power_Systems-orange.svg)
![License](https://img.shields.io/badge/License-MIT-purple.svg)

A MATLAB/Simulink project that implements a **real-time, physics-based anomaly detection system** for a 5-bus transmission network. It distinguishes **False Data Injection (FDI) cyber-attacks** from **genuine physical faults** using the correlation (or lack thereof) between voltage and current signals, and further sub-classifies detected physical faults into actionable categories for protective relaying.

> B.Tech Project — School of Electrical Sciences, Odisha University of Technology and Research, Bhubaneswar
> Author: **Ujjwal Keshri** (Reg. No. 23110546) | Supervisor: **Prof. A. K. Barisal** | 2025–26

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [How It Works](#how-it-works)
- [Repository Structure](#repository-structure)
- [System Model](#system-model)
- [Detection Algorithm — `detect_fdi()`](#detection-algorithm--detect_fdi)
- [Sub-Classification Algorithm — `classify_physical_fault()`](#sub-classification-algorithm--classify_physical_fault)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Outputs & Diagnostic Figures](#outputs--diagnostic-figures)
- [Results Summary](#results-summary)
- [Performance Comparison](#performance-comparison)
- [Future Scope](#future-scope)
- [References](#references)
- [Citation](#citation)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Overview

Modern smart grids depend on SCADA systems for real-time monitoring and control, which makes them vulnerable to **False Data Injection (FDI) attacks** — a class of stealthy cyber-attacks where an adversary manipulates sensor measurements without tripping conventional bad-data-detection (BDD) alarms. A key operational blind spot is that protective relays often cannot quickly tell whether a sudden voltage anomaly is a **cyber-attack** or a **real physical fault**, and misclassifying either has serious consequences (unnecessary outages vs. unprotected equipment damage).

This project implements two MATLAB functions that together form a lightweight, model-free, real-time detection pipeline:

1. **`detect_fdi()`** — classifies the system state every simulation step as:
   - `0` → Normal
   - `1` → Cyber-Attack (FDI)
   - `2` → Physical Fault
2. **`classify_physical_fault()`** — when a physical fault is flagged, sub-classifies it into:
   - `1` → Symmetrical (3-Phase) Fault
   - `2` → Unsymmetrical (Line-to-Ground) Fault
   - `3` → Reverse Power Flow (RPF)
   - `4` → Intermittent Fault (highest priority)

The core insight exploited is **V-I correlation**: a genuine physical fault causes voltage collapse *and* current surge simultaneously (correlated), whereas an FDI attack alters only the reported voltage signal while the true physical current remains unchanged (uncorrelated).

---

## Key Features

- **No network model or training data required** — purely threshold- and physics-based, unlike state-estimation or ML-based intrusion detection systems.
- **Real-time capable**: runs at `Ts = 50 µs` (20 kHz), suitable for protective relay time-scales.
- **Detects 5 distinct FDI attack modes**: Fake-Short, Fake-Sag, Fake-Swell, Replay Attack, Noise Injection.
- **Sub-classifies 4 physical fault types**: Symmetrical, Unsymmetrical, Reverse Power Flow, Intermittent.
- **Weighted event-scoring counter** with blanking/holdoff logic to suppress false positives during and after physical faults or breaker-open conditions.
- **Dual-flag architecture** (`flag` + `flag_cyber_raw`) to correctly handle simultaneous cyber + physical scenarios.
- **Fully documented, reproducible thresholds** — every constant is derived from baseline per-unit measurements (see [Detection Algorithm](#detection-algorithm--detect_fdi)).
- Six diagnostic figures for visual/ground-truth validation, including a combined waveform + detection-flag overlay.

---

## How It Works

The detector computes RMS voltage (`Vrms`) and RMS current (`Irms`) at Bus 5 and applies a single **voltage-boundary separator**:

```
V_boundary = 0.985 × V_mean_base = 0.6769 pu

is_phys_voltage  = (Vrms <  0.6769 pu)   → Physical domain
is_cyber_voltage = (Vrms >= 0.6769 pu)   → Cyber domain
```

- If an impedance/current anomaly is observed **while `is_phys_voltage` is true** → treated as a **physical fault** (`flag = 2`).
- If the same anomaly is observed **while `is_cyber_voltage` is true** → treated as an **FDI event** (`flag = 1`).

This single-boundary rule is reinforced by a **weighted cyber-event scoring counter** and a **reverse-power-flow (RPF) integrator** for robustness across all attack/fault types.

```
        INPUTS: ia, ib, ic, va, vb, vc
                     │
          Compute Vrms, Irms (RMS values)
                     │
     Core Principle: physical fault → correlated V & I
                      FDI attack     → uncorrelated V & I
                     │
        ┌────────────┴────────────┐
        │  Vrms < 0.6769 pu ?      │
        └────────────┬────────────┘
     Yes ─────────────┼───────────── No
        │                            │
 PHYSICAL DOMAIN                CYBER DOMAIN
 Z < Z_lower? Irms >            Z-anomaly? V_sag/swell?
 I_fault_th? dir_integral       Replay frozen? Noise var?
 <= -0.015?                            │
        │                              │
   flag = 2 (PHYSICAL)            flag = 1 (CYBER)
        │                              │
classify_physical_fault()      Weighted Scoring Counter
 Code 1: Symmetrical             (+5 / +2 per step,
 Code 2: Unsymmetrical            decays −5/step,
 Code 3: RPF                      confirmed at ≥10)
 Code 4: Intermittent
```

---

## Repository Structure

```
Cyber-attack-and-physical-fault-differentiation
├── data
│   ├── B5_AfterFault_data.csv
│   ├── B5_BeforeFault_data.csv
│   └── Cyber_Physical_System_Data.csv
├── docs
│   └── PPD_report_final.pdf
├── figures
│   ├── 3-Phase_Current_Comparison.png
│   ├── 3-Phase_Voltage_Comparison.png
│   ├── Bus_5_3-Phase_Manipulated_Cyber_Currents.png
│   ├── Bus_5_3-Phase_Manipulated_Cyber_Voltages.png
│   ├── Cyber_Data_and_Attack_Window_Overlay.png
│   ├── Figure 2 - Bus 5 - 3-Phase Manipulated Cyber Voltages.png
│   ├── Figure 3 - Bus 5 - 3-Phase Manipulated Cyber Currents.png
│   ├── Figure 6 - Cyber Data & Attack Window Overlay.png
│   ├── Plot 1A - Fault Classification Level.png
│   ├── Plot 1B - Anomaly Detection Flag.png
│   ├── Plot 1C - Cyber Attack Ground Truth.png
│   ├── Subplot 1 - Pre-Fault Steady State Current.png
│   ├── Subplot 1 - Pre-Fault Steady State Voltage.png
│   ├── Subplot 2 - Actual Physical Grid Current.png
│   ├── Subplot 2 - Actual Physical Grid Voltage.png
│   ├── Subplot 3 - Manipulated Cyber Output Current.png
│   ├── Subplot 3 - Manipulated Cyber Output Voltage.png
│   ├── System_Logic_and_Detection_Flags.png
│   └── vi relation.png
├── model
│   └── grid_5bus_fdi_detection.slx      # Simulink model (5-bus network + detect_fdi / classify_physical_fault blocks)
└── scripts
    ├── data_extraction.m                # Configure & run the simulation, extract logged data
    ├── plotting.m                       # Generate the diagnostic figures
    └── threshold_calculator.m           # Derive V_mean / I_mean / Z_mean baselines
 
```

> `detect_fdi()` and `classify_physical_fault()` live inside `model/grid_5bus_fdi_detection.slx` as MATLAB Function blocks.

---

## System Model

| Parameter | Value |
|---|---|
| System Base | 100 MVA |
| Buses | 5 (2 generator + 3 load) |
| Transmission Lines | 6 |
| Bus 1 (Slack) | 1.06 pu, 0° |
| Bus 2 (Generator) | 1.00 pu (regulated) |
| Total Active Load | ~283 MW |
| Solver | `ode4` fixed-step (Specialized Power Systems toolbox) |
| Sample Period (Ts) | 50 µs → 20 kHz |
| Nominal Frequency | 50 Hz |
| Monitoring Point | Bus 5 (FDI injection point) |

The FDI attack is implemented as a **signal-path bias injection** between the true physical voltage measurement and the input to `detect_fdi()` — it never touches the physical network, so true line currents stay unchanged. This is the exact asymmetry the detector exploits.

---

## Detection Algorithm — `detect_fdi()`

### Baseline parameters (derived from steady-state simulation)

| Symbol | Value | Meaning |
|---|---|---|
| `Z_mean_base` | 1.7702 pu | Steady-state V/I ratio at Bus 5 |
| `I_mean_base` | 0.3882 pu | Normal RMS current magnitude |
| `V_mean_base` | 0.6872 pu | Normal RMS voltage magnitude |
| `V_boundary` | 0.6769 pu | 98.5% of `V_mean_base` — cyber/physical separator |

### Derived thresholds

| Threshold | Formula | Value | Purpose |
|---|---|---|---|
| `Z_upper` | 1.25 × Z_mean_base | 2.2128 pu | High-impedance fault boundary |
| `Z_lower` | 0.75 × Z_mean_base | 1.3277 pu | Low-impedance short-circuit boundary |
| `I_fault_th` | 1.30 × I_mean_base | 0.5047 pu | Overcurrent / fake-short threshold |
| `I_breaker` | 0.30 × I_mean_base | 0.1165 pu | Dead-bus / breaker-open suppression |
| `V_sag_th` | 0.95 × V_mean_base | 0.6528 pu | Fake-sag lower boundary |
| `V_swell_th` | 1.05 × V_mean_base | 0.7216 pu | Fake-swell upper boundary |
| Noise threshold | 20 × (0.02 × I_mean)² | 0.001206 | Rolling variance threshold |
| RPF threshold | `dir_integral ≤ −0.015 pu·s` | — | Reverse power-flow gate |

### FDI attack modes detected

| # | Mode | Condition | Score/step |
|---|---|---|---|
| 1 | Fake-Short | `Z < Z_lower` AND `Irms > I_fault_th`, cyber-voltage domain | +5 |
| 2 | Fake-Sag | `Vrms < V_sag_th` AND `Irms > 0.5×I_mean` | +5 |
| 3 | Fake-Swell | `Vrms > V_swell_th` AND `Irms > 0.2717 pu` | +5 |
| 4 | Replay Attack | `delta_v < 1e-3` for >5 consecutive steps | +2 |
| 5 | Noise Injection | rolling 20-sample variance > 0.001206 | +2 |

A **weighted scoring counter** (`cyber_count`) accumulates these scores, decays by −5/step with no active condition, and confirms a cyber-attack once `cyber_count ≥ 10`. The counter is reset and blanked for 200 steps (10 ms) after a physical fault clears, and while the breaker is open (`Irms < I_breaker`).

### Timing parameters

| Parameter | Value | Duration |
|---|---|---|
| Sample period (Ts) | 50 µs | — |
| Physical fault confirm | `fault_count ≥ 3` | 150 µs |
| Fault latch duration | 250 steps | 12.5 ms |
| Cyber holdoff post-fault | 200 steps | 10.0 ms |
| Replay frozen threshold | `frozen_count > 5` | 250 µs |
| Noise buffer size | 20 samples | 1.0 ms |
| Intermittent window | 4000 steps | 200 ms |
| RMS rolling buffer | 400 samples | 20 ms (1 cycle) |

**Function I/O:**
```
Inputs : ia, ib, ic, va, vb, vc   (instantaneous 3-phase currents/voltages)
Outputs: flag (0/1/2), flag_cyber_raw
Persistent state: cyber_count, fault_count, fault_latch, dir_integral,
                  frozen_count, noise_var_buf, is_rpf_active
```

---

## Sub-Classification Algorithm — `classify_physical_fault()`

Activated only when `flag == 2`. Outputs a `fault_code` (0–4) via a strict priority ladder:

| Code | Fault Type | Criterion | Priority |
|---|---|---|---|
| 0 | Normal | `flag ≠ 2` (gatekeeper) | — |
| 4 | Intermittent | ≥3 flag=2 transitions within 200 ms | **Highest** (overrides all) |
| 3 | Reverse Power Flow | `dir_integral ≤ −0.015 pu·s` during flag=2 | 2nd |
| 2 | Unsymmetrical (L-G) | phase-current unbalance > 15% | 3rd |
| 1 | Symmetrical (3-Phase) | phase-current unbalance ≤ 15% (default) | Lowest |

Phase-current unbalance (computed from rolling 400-sample / 1-cycle RMS buffers):

```
unbalance = max(|Ia_rms − Iavg|, |Ib_rms − Iavg|, |Ic_rms − Iavg|) / Iavg_rms
```

**Function I/O:**
```
Inputs : ia, ib, ic, va, vb, vc, flag (from detect_fdi)
Outputs: fault_code (0–4)
```

---

## Requirements

- MATLAB R2021b or later (recommended)
- Simulink
- Simscape Electrical → **Specialized Power Systems** toolbox
- No additional toolboxes or external datasets required

---

## Getting Started

```bash
git clone https://github.com/<your-username>/Cyber-attack-and-physical-fault-differentiation.git
cd Cyber-attack-and-physical-fault-differentiation
```

1. Open MATLAB and set the repository root as your working directory (or add it to path).
2. Open `model/grid_5bus_fdi_detection.slx` in Simulink.
3. Run `scripts/threshold_calculator.m` once to (re-)derive `V_mean_base`, `I_mean_base`, `Z_mean_base` for your network configuration, if you modify the topology or loading.
4. Run the simulation (see [Usage](#usage)).

---

## Usage

### Run the full simulation

```matlab
run('scripts/data_extraction.m')
```

This will:
- Simulate 4 s of operation with sequential injection of all 5 FDI attack modes and all 4 physical fault types
- Log `flag`, `flag_cyber_raw`, and `fault_code` time series
- Export the logged data to `data/` (e.g., `Cyber_Physical_System_Data.csv`)

### Generate diagnostic figures

```matlab
run('scripts/plotting.m')
```

Produces the six diagnostic figures described below, saved to `figures/`.

### Use the functions standalone

`detect_fdi()` and `classify_physical_fault()` are implemented as **MATLAB Function blocks inside** `model/grid_5bus_fdi_detection.slx`. To run them outside Simulink, open each block, copy its code into a `.m` file of the same name on your MATLAB path, and call it on your own logged V-I data streams:

```matlab
[flag, flag_cyber_raw] = detect_fdi(ia, ib, ic, va, vb, vc);
fault_code = classify_physical_fault(ia, ib, ic, va, vb, vc, flag);
```

> Note: both functions use **persistent variables** to maintain state across calls — reset the workspace / clear functions between independent simulation runs.

---

## Outputs & Diagnostic Figures

All figures are in `figures/`.

| Fig. | Description | File |
|---|---|---|
| 5.1A | Fault Classification Level (`fault_code`, 0–4) over time | `Plot 1A - Fault Classification Level.png` |
| 5.1B | Anomaly Detection Flag (`flag`: 0=Normal, 1=Cyber, 2=Physical) | `Plot 1B - Anomaly Detection Flag.png` |
| 5.1C | Cyber Attack Ground-Truth Window (injection control signal) | `Plot 1C - Cyber Attack Ground Truth.png` |
| 5.2 | Bus 5 — manipulated 3-phase cyber voltages | `Bus_5_3-Phase_Manipulated_Cyber_Voltages.png` |
| 5.3 | Bus 5 — manipulated 3-phase cyber currents (shows true physical current is unaffected) | `Bus_5_3-Phase_Manipulated_Cyber_Currents.png` |
| 5.4A–C | Pre-fault / actual physical / manipulated cyber 3-phase voltage comparison | `3-Phase_Voltage_Comparison.png` |
| 5.5A–C | Pre-fault / actual physical / manipulated cyber 3-phase current comparison | `3-Phase_Current_Comparison.png` |
| 5.6 | **Cyber Data & Attack Window Overlay** — waveform + `flag_cyber_raw` + shaded ground-truth attack windows (key validation plot) | `Cyber_Data_and_Attack_Window_Overlay.png` |

Additional plots: `System_Logic_and_Detection_Flags.png` (detection logic and flags) and `vi relation.png` (V-I relationship).

---|---|
| 5.1A | Fault Classification Level (`fault_code`, 0–4) over time |
| 5.1B | Anomaly Detection Flag (`flag`: 0=Normal, 1=Cyber, 2=Physical) |
| 5.1C | Cyber Attack Ground-Truth Window (injection control signal) |
| 5.2 | Bus 5 — manipulated 3-phase cyber voltages |
| 5.3 | Bus 5 — manipulated 3-phase cyber currents (shows true physical current is unaffected) |
| 5.4A–C | Pre-fault / actual physical / manipulated cyber 3-phase voltage comparison |
| 5.5A–C | Pre-fault / actual physical / manipulated cyber 3-phase current comparison |
| 5.6 | **Cyber Data & Attack Window Overlay** — waveform + `flag_cyber_raw` + shaded ground-truth attack windows (key validation plot) |

---

## Results Summary

- **All 5 FDI attack modes** correctly detected (`flag = 1`), with **zero spurious physical-fault alarms** (`fault_code = 0` throughout every cyber window).
- **All 4 physical fault types** correctly sub-classified, with detection within **150 µs (3 samples)** of fault inception.
- **Cyber detection latency**: ~100 µs for magnitude-based attacks (Modes 1–3), ~250 µs for pattern-based attacks (Replay/Noise, Modes 4–5).
- Dual-flag output (`flag` + `flag_cyber_raw`) correctly prioritizes physical-fault relay action while independently signalling co-occurring cyber intrusion.

| Attack Mode | Condition | flag | fault_code |
|---|---|---|---|
| Fake-Short | `Z < 1.3277`, cyber-voltage | 1 | 0 |
| Fake-Sag | `Vrms < 0.6528`, cyber-voltage | 1 | 0 |
| Fake-Swell | `Vrms > 0.7216`, cyber-voltage | 1 | 0 |
| Replay Attack | frozen > 250 µs | 1 | 0 |
| Noise Injection | rolling variance > 0.001206 | 1 | 0 |

| Fault Type | Detection Time | flag | fault_code |
|---|---|---|---|
| Symmetrical (3-Phase) | 150 µs | 2 | 1 |
| Unsymmetrical (L-G) | 150 µs | 2 | 2 |
| Reverse Power Flow | `dir_integral ≤ −0.015` | 2 | 3 |
| Intermittent | 3 transitions / 200 ms | 2 | 4 |

---

## Performance Comparison

| Parameter | Proposed V-I Correlation | State-Est. BDD | ML-Based IDS | Data-Driven (Anwar et al.) |
|---|---|---|---|---|
| Sample period | 50 µs | Iteration-dependent | Batch/stream | Offline |
| Cyber detection speed | 100–250 µs | Iteration delay | Inference delay | Post-processing |
| Physical fault speed | 150 µs (3 samples) | State update | Inference delay | Post-processing |
| Network model needed | No | Yes (Y-bus) | No | No |
| Training data needed | No | No | Yes (large) | Yes |
| FDI attack types | 5 modes | Residual anomaly only | Multiple | Statistical only |
| Fault sub-classification | 4 types | None | Possible | None |
| Dual flag output | Yes | No | No | No |
| False-positive suppression | Weighted counter + blanking | Threshold only | Model-dependent | Statistical |

---

## Future Scope

- Extend to larger benchmark networks (IEEE 14-, 30-, 118-bus) to evaluate scalability.
- Investigate **coordinated attacks** (FDI injected during an active physical fault) to stress-test misclassification resistance.
- Integrate PMU synchrophasor data to improve RPF and intermittent-fault sensitivity.
- Adaptive baseline calibration to auto-update `V_mean_base`, `I_mean_base`, `Z_mean_base` under changing load conditions.
- Hardware-in-the-Loop (HIL) validation on RTDS / OPAL-RT real-time simulators.
- Extend to inverter-dominated microgrids with different fault-current signatures.
- Explore multi-point FDI attacks targeting several buses/sensors simultaneously.
- Align with **IEC 62351** (cybersecurity) and **IEC 61850** (substation automation) standards.

---

## References

1. A. Anwar, A. N. Mahmood, Z. Tari, "A data-driven approach to distinguish cyber-attacks from physical faults in a smart grid," *Proc. 8th Int. Conf. Secur. Inf. Netw. (SIN)*, 2015.
2. "Centralized dynamic state estimation algorithm for detecting and distinguishing faults and cyber-attacks in power systems," IEEE Xplore, 2025.
3. M. M. Aman, G. B. Jasmon, Q. A. Khan, A. H. B. Abu Bakar, J. J. Jamian, "Modeling and simulation of reverse power relay for generator protection," *Proc. IEEE Int. Power Eng. Optim. Conf. (PEOCO)*, 2012, pp. 317–322.
4. S. Sridhar, A. Hahn, M. Govindarasu, "Cyber-physical system security for the electric power grid," *Proc. IEEE*, vol. 100, no. 1, pp. 210–224, 2012.
5. V. S. Rajkumar, M. Tealane, A. Ştefanov, A. Presekal, P. Palensky, "Cyber Attacks on Power System Automation and Protection and Impact Analysis," *2020 IEEE PES Innovative Smart Grid Technologies Europe (ISGT-Europe)*, 2020. doi: 10.1109/ISGTEurope47291.2020.9248840

---

## Citation

If you use this work, please cite:

```
Ujjwal Keshri, "Simulating Power Grid Cyber-Attacks: Utilizing V-I Correlation to
Differentiate FDI Attacks from Physical Faults," B.Tech Project Report, School of
Electrical Sciences, Odisha University of Technology and Research, Bhubaneswar, 2026.
```
---

## Acknowledgements

Developed under the guidance of **Prof. A. K. Barisal**, Professor, School of Electrical Sciences, Odisha University of Technology and Research, Bhubaneswar, as part of the B.Tech in Electrical Engineering curriculum (2025–26).
