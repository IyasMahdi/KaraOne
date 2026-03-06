# 🧠 EEG Pre-Processing Pipeline — KARA ONE Dataset
### Imagined Speech Recognition from Neural Signals

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-orange?style=flat-square&logo=mathworks)](https://www.mathworks.com/)
[![EEGLAB](https://img.shields.io/badge/EEGLAB-2022.0%2B-blue?style=flat-square)](https://sccn.ucsd.edu/eeglab/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square)]()

---

## 📌 Overview

This repository implements a **full EEG pre-processing pipeline** for the [KARA ONE dataset](http://www.cs.toronto.edu/~complingweb/data/karaOne/karaOne.html) — a benchmark dataset for **imagined speech and motor imagery classification** using electroencephalography (EEG).

The pipeline transforms raw, noisy EEG recordings into clean, structured, windowed data ready for machine learning and feature extraction — bridging the gap between raw neural signals and brain-computer interface (BCI) applications.

> 💡 **Why this matters:** Decoding imagined speech from brain signals has profound implications for assistive communication technology, enabling people with motor disabilities to communicate through thought alone.

---

## 🗂️ Dataset

**KARA ONE** — University of Toronto  
8 subjects: `MM05`, `MM10`, `MM11`, `MM16`, `MM18`, `MM19`, `MM21`, `P02`  
64-channel EEG, recorded during imagined and vocalized speech tasks across 11 phonemic/syllabic prompts.

---

## ⚙️ Pipeline Architecture

```
Raw .cnt EEG Recording
        │
        ▼
┌───────────────────────┐
│  1. Data Loading       │  pop_loadcnt — load raw Neuroscan .cnt files
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  2. Channel Removal    │  Remove non-EEG channels → retain 64 channels
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  3. Band-Pass Filter   │  1–50 Hz (pop_eegfiltnew) — remove DC drift & HF noise
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  4. Eye-Movement       │  H-infinity regression on EOG channels (VEO, HEO)
│     Correction         │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  5. EOG Channel        │  Remove oculomotor channels → 62 channels remain
│     Removal            │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  6. Channel Locations  │  Assign standard 10-20 electrode coordinates
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  7. Common Average     │  CAR — subtract mean across channels to reduce
│     Reference (CAR)    │  common-mode noise
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  8. ICA Decomposition  │  Extended Infomax ICA (runica) — blind source separation
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  9. Artifact Labelling │  ICLabel — automated component classification
│     & Removal          │  (muscle, eye, heart, line noise, channel noise)
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│ 10. Epoch Segmentation │  Segment by thinking_inds — isolate imagined speech trials
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│ 11. Sliding Window     │  100ms windows, 50ms overlap → structured trial frames
│     Framing            │
└───────────┬───────────┘
            │
            ▼
   Structured .mat Output
  (prompts | EEG | windowed data)
```

---

## 🔬 Technical Details

| Stage | Method | Parameters |
|---|---|---|
| Bandpass Filter | FIR (pop_eegfiltnew) | 1–50 Hz |
| EOG Correction | H-infinity Regression | μ=5×10⁻³, λ=1×10⁻⁵, γ=1.5 |
| ICA | Extended Infomax (runica) | Extended mode = ON |
| Artifact Classification | ICLabel | Visual inspection + auto-label |
| Epoch Reference | `epoch_inds.mat` | `thinking_inds` only |
| Window Size | Sliding window | 100 ms (500 samples @ 5 kHz) |
| Window Overlap | 50% | 50 ms step |

---

## 📁 Repository Structure

```
📦 KARA-EEG-Preprocessing/
 ┣ 📜 PP1_preprocessing.m       # Main preprocessing pipeline
 ┣ 📜 split_data.m              # Helper: segment EEG by trial indices
 ┣ 📂 Recordings/
 ┃ ┣ 📂 MM05/
 ┃ ┃ ┣ 📄 *.cnt                 # Raw EEG recording
 ┃ ┃ ┣ 📄 epoch_inds.mat        # Trial segmentation indices
 ┃ ┃ ┗ 📂 kinect_data/
 ┃ ┃   ┗ 📄 labels.txt          # Prompt labels
 ┃ ┣ 📂 MM10/ ...
 ┃ ┗ 📂 [other subjects]/
 ┗ 📜 README.md
```

---

## 🚀 Getting Started

### Prerequisites

- MATLAB R2021b or later
- [EEGLAB](https://sccn.ucsd.edu/eeglab/) (with the following plugins):
  - `pop_eegfiltnew` — filtering
  - `pop_hinftv_regression` — H-infinity EOG correction
  - `pop_runica` / `runica` — ICA decomposition
  - `ICLabel` — automated artifact classification
  - `pop_viewprops` — component visualisation

### Installation

```matlab
% 1. Clone the repository
% git clone https://github.com/your-username/KARA-EEG-Preprocessing.git

% 2. Add paths in MATLAB
addpath(genpath('path/to/Recordings'));
addpath(genpath('path/to/EEGLAB'));

% 3. Run the pipeline
PP1_preprocessing
```

### Output

For each subject, the pipeline saves a processed `.mat` file to:
```
Recordings/<SubjectID>/PP-WDATA/
```

Each output contains:
- `EEG_Data.prompts` — cell array of imagined speech labels
- `EEG_Data.EEG` — segmented EEG trials (thinking phase only)
- `EEG_Data.Data` — full cleaned EEG data
- `all_trials` — windowed and framed trial data ready for feature extraction

---

## 🧩 Key Design Decisions

**Why H-infinity regression for EOG?**  
Unlike simple subtraction, H-infinity regression is a robust adaptive filter that minimises ocular contamination while preserving neural signal integrity — critical for frontal electrode fidelity.

**Why extended ICA?**  
The `extended` mode of Infomax ICA handles both sub-Gaussian and super-Gaussian source distributions, making it more robust for mixed EEG artifact profiles (muscle + cardiac + line noise).

**Why 100ms windows with 50% overlap?**  
100ms captures a meaningful neural temporal epoch while the 50% overlap doubles temporal resolution for downstream classifiers without introducing excessive redundancy.

---

## 📊 Subjects & Data

| Subject | Trials | Notes |
|---------|--------|-------|
| MM05 | — | Standard recording |
| MM10 | — | Standard recording |
| MM11 | — | Standard recording |
| MM16 | — | Standard recording |
| MM18 | — | Standard recording |
| MM19 | — | Standard recording |
| MM21 | — | Standard recording |
| P02  | — | Patient subject |

---

## 🔭 Next Steps / Roadmap

- [ ] Feature extraction (PSD, CSP, wavelet coefficients)
- [ ] Classification pipeline (SVM, LDA, deep learning)
- [ ] Cross-subject generalisation experiments
- [ ] Real-time BCI inference module

---

## 📚 References

- Zhao, S., & Ruber, F. (2015). *KARA ONE: A Phoneme Labelled Imagined and Articulated Speech EEG Dataset.* University of Toronto.
- Delorme, A., & Makeig, S. (2004). EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics. *Journal of Neuroscience Methods*, 134(1), 9–21.
- Parra, L. C., et al. (2005). Recipes for the linear analysis of EEG. *NeuroImage*, 28(2), 326–341.

---

## 👤 Author

**Mahdi Rabih Berair**  
*BSc/MEng — Biomedical / Electrical Engineering*  
📧 [your.email@university.ac.uk] · 🔗 [LinkedIn](https://linkedin.com) · 🐙 [GitHub](https://github.com)

---

> *This project forms part of an ongoing research effort in non-invasive brain-computer interface development and neural decoding of imagined speech.*