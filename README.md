# Physics-Based Intrusion Detection System (IDS) for SCADA Grids ⚡🛡️

![MATLAB](https://img.shields.io/badge/MATLAB-R2023a+-blue.svg)
![Simulink](https://img.shields.io/badge/Simulink-Power_Systems-orange.svg)
![AppDesigner](https://img.shields.io/badge/UI-App_Designer-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-purple.svg)

## Overview
As power grids become smarter, they become increasingly vulnerable to **False Data Injection (FDI)** cyber-attacks. If a hacker breaches a substation's SCADA network, they can spoof voltage sensor data to trick human operators into unnecessarily tripping critical breakers, causing widespread blackouts.

This project introduces a **Cyber-Physical Intrusion Detection System (IDS)** built in MATLAB/Simulink. Rather than relying solely on network-layer cybersecurity, this IDS leverages the immutable laws of grid physics (Ohm's Law / V-I Correlation) to instantly differentiate a hacker spoofing data from a true physical transmission line fault. 

## 🚀 Key Features

* **Physics-Based Verification:** Analyzes real-time Per-Unit (p.u.) RMS Voltage and Current to detect data anomalies that violate physical electrical laws.
* **5-State Fault Classifier:** Automatically calculates zero-sequence (ground) current and broken phase counts to classify events into 5 distinct states:
  * `State 1`: Single Line-to-Ground (LG) Fault
  * `State 2`: Line-to-Line (LL) Fault
  * `State 3`: Double Line-to-Ground (LLG) Fault
  * `State 4`: Three-Phase (LLL) Collapse
  * `State 5`: SCADA FDI Cyber-Attack
* **Standalone SCADA Dashboard (HMI):** A custom MATLAB App Designer interface providing a real-time control room view of grid health, complete with color-coded diagnostic alerts and multi-pane timeline plotting.

---

## 🧠 How It Works (The V-I Correlation Logic)
Hackers can manipulate digital SCADA data, but they cannot easily alter physical grid inertia.

1. **The Physical Fault:** When a tree hits a power line, physics dictates that the line voltage will collapse (e.g., < 0.55 p.u.) AND the physical fault current will violently spike (e.g., > 5.0 p.u.). 
2. **The Cyber Attack:** When a hacker manipulates the RTU to report a voltage drop, the IDS cross-references the current sensors. If the voltage breaches the 5% tolerance band but the current remains resting normally at 1.0 p.u., the data is mathematically impossible. The IDS flags the data as a `State 5` Cyber-Attack and blocks the breaker trip signal.

---

## 🛠️ Technology Stack
* **Simulation Engine:** MATLAB & Simulink
* **Grid Physics:** Simscape Electrical / Specialized Power Systems (`powergui`)
* **Control Logic:** MATLAB Function Blocks
* **UI / Dashboard:** MATLAB App Designer (`.mlapp`)
* *(Optional External Link)*: OPC Toolbox integration tested for Matrikon OPC Server & InTouch Wonderware SCADA.
