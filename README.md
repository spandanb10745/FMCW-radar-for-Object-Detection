# FMCW Radar for Object Detection 📡

![IITG Logo](Images/iitg_logo.png)
*Department of Electronics and Communication Engineering, Indian Institute of Technology, Guwahati*

This repository contains the hardware design, theoretical models, and digital signal processing (DSP) algorithms for a custom-built Frequency-Modulated Continuous Wave (FMCW) radar. The system is designed to detect both stationary distances and track moving targets (human radial velocity) using a 2.4 GHz center frequency.

## 📋 Table of Contents
* [Overview & Principles](#overview--principles)
* [Hardware Architecture](#hardware-architecture)
* [Signal Processing & DSP](#signal-processing--dsp)
* [System Integration](#system-integration)
* [Results](#results)
* [Future Improvements](#future-improvements)
* [Repository Structure](#repository-structure)
* [References](#references)
* [Acknowledgements](#acknowledgements)

---

## 🔬 Overview & Principles
Unlike pulsed radar, an FMCW radar transmits a continuous signal modulated over time. We use a linear triangular ramp to sweep the frequency from the start frequency to the stop frequency. 

![System Flow Diagram](Images/Flow.png)

When the transmitted signal reflects off a target, it returns after a time delay. By mixing the transmitted and received signals, we generate a "beat" frequency. The range of the target is directly proportional to this beat frequency:

$$R = \frac{c \cdot T_p \cdot f_b}{2 \cdot B}$$

Where $T_p$ is the sweep time (23 ms), $B$ is the bandwidth (~300 MHz), and $c$ is the speed of light.

---

## 🛠️ Hardware Architecture

### 1. Antennas
Custom-designed pyramidal horn antennas (WR340 waveguide standard) optimized for 2.4 GHz. 
* **Material:** 3D-printed PLA wrapped in conductive aluminum tape.
* **Design Generation:** The optimal dimensions were calculated using Balanis' iterative root-finding equations (see `Antenna/antenna_design.py`).

<p align="center">
  <img src="Images/printing_horn_antenna.jpg" width="45%" alt="3D Printing Horn Antenna">
  <img src="Images/Pyramidal_Antenna.png" width="45%" alt="Pyramidal Antenna Dimensions">
</p>

**Performance:** Testing confirmed a gain of -10 dB at 2.4 GHz. Orthogonal placement yields -42 dB isolation, mitigating TX-to-RX cross-talk.

<p align="center">
  <img src="Images/Antenna_gain.png" width="45%" alt="Antenna Gain">
  <img src="Images/Antenna_orthogonal.png" width="45%" alt="Antenna Orthogonal">
</p>

### 2. Modulation & RF Front-End
* **Ramp Circuit:** A custom triangle wave generator using an operational amplifier Schmitt trigger and integrator, biased at a 4.2V DC offset. This drives the VCO to generate the 2.4 GHz RF sweep.

**Ramp Circuit Design & Simulation:**
<p align="center">
  <img src="Images/Ramp_circuit_ltspice.png" width="30%" alt="Ramp LTSpice">
  <img src="Images/Ramp_lt_spice_simulation.png" width="30%" alt="Ramp Simulation">
  <img src="Images/Ramp_Output.png" width="30%" alt="Ramp Output Oscilloscope">
</p>

![Physical Ramp Circuit](Images/Ramp_circuit.png)

*(Note: The RF front-end also utilizes a VCO, Power Splitter, Low Noise Amplifier, and Frequency Mixer. Refer to the project report for exact component numbers and specifications).*

### 3. Signal Conditioning
* **Thomas Biquad Low Pass Filter:** An orthogonally tunable active filter that simultaneously amplifies the weak beat signal and strips high-frequency noise.

<p align="center">
  <img src="Images/Thomas_Low_pass_filter.png" width="45%" alt="Thomas LPF Schematic">
  <img src="Images/Thomas_Low_pass_filter_real.png" width="45%" alt="Thomas LPF Physical">
</p>

* **Sync Circuit:** Attenuates and level-shifts the raw square wave from the Schmitt trigger into a 0V-centered, line-level synchronization pulse for the ADC.

<p align="center">
  <img src="Images/Sync_circuit_ltspice.png" width="30%" alt="Sync LTSpice Schematic">
  <img src="Images/Sync_lt_spice_simulation.png" width="30%" alt="Sync Simulation">
  <img src="Images/Sync_circuit.png" width="30%" alt="Sync Circuit Physical">
</p>

---

## 🔌 System Integration

Integrating the radar required careful power management across four separate DC power sources and one split supply. The entire setup was monitored continuously using a 3-channel oscilloscope.

![Flowchart of Design](Images/Flowchart_of_design.png)

<p align="center">
  <img src="Images/Full_setup.jpg" width="45%" alt="Full Hardware Setup">
  <img src="Images/Setup.jpg" width="45%" alt="Testing Environment Setup">
</p>

---

## 💻 Signal Processing & DSP
Analog-to-Digital Conversion is handled via a standard stereo TRS input (Left = Sync, Right = Radar Data) into a laptop. The raw `.wav` files are processed in MATLAB.

![Digital Processing](Images/Digital_Processing.png)

* **Stationary Targets (RTI):** Pulse slicing is followed by an Inverse Fast Fourier Transform (IFFT) to convert beat frequency bins into physical distances, plotted as a Range-Time Intensity (RTI) heatmap.
* **Moving Targets (MTI):** Stationary clutter is mathematically erased by subtracting the arithmetic mean of all pulses. The peak range is tracked, smoothed, and differentiated to estimate velocity, followed by median filtering.

---

## 📊 Results

### Stationary Target Detection
Successfully detected structural boundaries (e.g., roof detection) with solid horizontal magnitude responses on the RTI plot.

<p align="center">
  <img src="Images/Stationary_detection.png" width="45%" alt="Stationary Full Range">
  <img src="Images/Stationaryzoomed.png" width="45%" alt="Stationary Zoomed">
</p>

### Moving Object Detection
Clean isolation of human movement (walking towards and away from the radar) with an accurate, smoothed radial velocity trajectory, entirely unhindered by background static clutter.

<p align="center">
  <img src="Images/Moving_object_detection.png" width="45%" alt="Moving Object Detection MTI">
  <img src="Images/Velocity_Detection.png" width="45%" alt="Velocity Detection">
</p>

---

## 🚀 Future Improvements
1.  **SoC Tape-Out:** Migrating from discrete components to a custom Radio Frequency Integrated Circuit (RFIC) with planar microstrip patch antennas to reduce parasitics and footprint.
2.  **Embedded Edge Processing:** Replacing the laptop soundcard with an ARM Cortex-M microcontroller (e.g., STM32H7) to perform real-time 1D FFTs using onboard SRAM.
3.  **Linearization:** Implementing a Fractional-N PLL synthesizer to correct thermal drift and ramp non-linearity at the frequency extremes.
4.  **Millimeter Wave (mmWave):** Scaling to 24 GHz, 60 GHz, or 77 GHz ISM bands for vastly improved range resolution and phased array Angle of Arrival (AoA) capabilities.

---

