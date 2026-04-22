# FMCW Radar for Object Detection 📡

![IITG](Images/iitg_logo.png) 
*Department of Electronics and Communication Engineering, Indian Institute of Technology, Guwahati*

This repository contains the hardware design, theoretical models, and digital signal processing (DSP) algorithms for a custom-built Frequency-Modulated Continuous Wave (FMCW) radar. The system is designed to detect both stationary distances and track moving targets (human radial velocity) using a 2.4 GHz center frequency.

## 📋 Table of Contents
* [Overview & Principles](#overview--principles)
* [Hardware Architecture](#hardware-architecture)
* [Signal Processing & DSP](#signal-processing--dsp)
* [Results](#results)
* [Future Improvements](#future-improvements)
* [Repository Structure](#repository-structure)
* [Authors](#authors)

---

## 🔬 Overview & Principles
Unlike pulsed radar, an FMCW radar transmits a continuous signal modulated over time. We use a linear triangular ramp to sweep the frequency from $f_{\text{start}}$ to $f_{\text{stop}}$. 

When the transmitted signal reflects off a target, it returns after a time delay $\Delta t = 2R/c$. By mixing the transmitted and received signals, we generate a "beat" frequency ($f_b$). The range $R$ of the target is directly proportional to this beat frequency:

$$R = \frac{c \cdot T_p \cdot f_b}{2 \cdot B}$$

Where $T_p$ is the sweep time (23 ms), $B$ is the bandwidth ($\sim$300 MHz), and $c$ is the speed of light.

---

## 🛠️ Hardware Architecture

### 1. Antennas
Custom-designed pyramidal horn antennas (WR340 waveguide standard) optimized for 2.4 GHz. 
* **Material:** 3D-printed PLA wrapped in conductive aluminum tape.
* **Performance:** -10 dB gain at 2.4 GHz. Orthogonal placement yields -42 dB isolation, mitigating TX-to-RX cross-talk.
* **Design Generation:** The optimal dimensions were calculated using Balanis' iterative root-finding equations (see `Antenna/antenna_design.py`).

### 2. Modulation & RF Front-End
* **Ramp Circuit:** A custom triangle wave generator using an operational amplifier Schmitt trigger and integrator, biased at a 4.2V DC offset.
* **VCO (ROS-3800-119R+):** Driven by the ramp circuit to generate the 2.4 GHz RF sweep.
* **Power Splitter (ZX10-2-442-S+):** Divides the VCO output into the Tx antenna and the Local Oscillator (LO) reference.
* **LNA (ZX60-272LN-S+):** Boosts the weak reflected Rx signal (14 dB gain, 0.8 dB noise figure).
* **Frequency Mixer (ZX05-43MH-S+):** Multiplies the LO and Rx signals to extract the baseband IF beat frequency.

### 3. Signal Conditioning
* **Thomas Biquad Low Pass Filter:** An orthogonally tunable active filter ($Q = 0.707$, $f_c = 15\text{ kHz}$) that simultaneously amplifies the weak beat signal and strips high-frequency noise.
* **Sync Circuit:** Attenuates and level-shifts the raw square wave from the Schmitt trigger into a 0V-centered, line-level synchronization pulse for the ADC.

---

## 💻 Signal Processing & DSP
Analog-to-Digital Conversion is handled via a standard stereo TRS input (Left = Sync, Right = Radar Data). The raw `.wav` files are processed in MATLAB.

### Stationary Targets (RTI)
* **Pulse Slicing:** The continuous stream is chopped into a 2D matrix mapping Slow-Time (pulses) against Fast-Time (samples).
* **Range Transformation:** Applying an Inverse Fast Fourier Transform (IFFT) converts the beat frequency bins into physical distances, plotted as a Range-Time Intensity (RTI) heatmap.

### Moving Targets (MTI)
* **Background Cancellation:** Stationary clutter is mathematically erased by subtracting the arithmetic mean of all pulses ($RP_{mti} = RP - \text{mean}(RP, 1)$).
* **Velocity Estimation:** The peak range is tracked, smoothed, and differentiated ($v(t) = \frac{\Delta R(t)}{\Delta t}$). 
* **Nonlinear Filtering:** A median filter and deadzone thresholding (0.25 m/s) are applied to suppress bin-switching jitter and thermal noise.

---

## 📊 Results

* **Stationary:** Successfully detected structural boundaries (e.g., roof detection) with solid horizontal magnitude responses on the RTI plot.
* **Moving:** Clean isolation of human movement (walking towards and away from the radar) with an accurate, smoothed radial velocity trajectory, entirely unhindered by background static clutter.

*(Ensure your images are placed in the `Images/` directory for them to render properly in the repository!)*

---

## 🚀 Future Improvements
1.  **SoC Tape-Out:** Migrating from discrete components to a custom Radio Frequency Integrated Circuit (RFIC) with planar microstrip patch antennas to reduce parasitics and footprint.
2.  **Embedded Edge Processing:** Replacing the laptop soundcard with an ARM Cortex-M microcontroller (e.g., STM32H7) to perform real-time 1D FFTs using onboard SRAM.
3.  **Linearization:** Implementing a Fractional-N PLL synthesizer to correct thermal drift and ramp non-linearity at the frequency extremes.
4.  **Millimeter Wave (mmWave):** Scaling to 24 GHz, 60 GHz, or 77 GHz ISM bands for vastly improved range resolution and phased array Angle of Arrival (AoA) capabilities.

---

## 📁 Repository Structure

```text
fmcw-radar/
├── README.md
├── Report.pdf                  # Comprehensive project report and theoretical breakdown
├── Antenna/
│   └── antenna_design.py       # Iterative Python script for horn dimensions
├── Images/                     # Hardware setup photos, schematic screenshots, and plots
├── Matlab/
│   ├── Radar_stationary.m      # MATLAB script for stationary target detection
│   ├── Radar_moving.m          # MATLAB script for MTI and velocity extraction
│   ├── moving_44100_sam.wav    # WAV file containing moving target data
│   ├── mv.wav                  # Sample audio recording (moving)
│   ├── stat.wav                # Sample audio recording (stationary)
│   └── Stationary_roof_final.wav # WAV file containing stationary roof data
└── Videos/                     # Demonstration and testing videos
