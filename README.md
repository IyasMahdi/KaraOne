# EEG Pre-Processing Pipeline — KARA ONE Dataset
## Imagined Speech Recognition from Neural Signals

[![MATLAB](https://img.shields.io/badge/MATLAB-R2021b%2B-orange?style=flat-square&logo=mathworks)](https://www.mathworks.com/)
[![EEGLAB](https://img.shields.io/badge/EEGLAB-2022.0%2B-blue?style=flat-square)](https://sccn.ucsd.edu/eeglab/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square)]()

## Overview

This repository implements a full EEG pre-processing pipeline for the [KARA ONE dataset](http://www.cs.toronto.edu/~complingweb/data/karaOne/karaOne.html), a benchmark dataset for imagined speech and motor imagery classification using electroencephalography (EEG).

The pipeline takes raw, noisy EEG recordings and produces clean, structured, windowed data ready for feature extraction and classification. It covers the full signal chain: filtering, ocular artifact correction, blind source separation, artifact rejection, epoching, and windowing.

The broader goal is decoding imagined (unspoken) speech from EEG, a core problem in non-invasive brain-computer interface (BCI) research with applications in assistive communication for people with severe motor impairments.

## Dataset

KARA ONE (University of Toronto). Eight subjects: `MM05`, `MM10`, `MM11`, `MM16`, `MM18`, `MM19`, `MM21`, `P02`. 64-channel EEG recorded during imagined and vocalized speech across 11 phonemic and syllabic prompts.

## Pipeline Architecture

```
Raw .cnt EEG Recording
        |
        v
1.  Data Loading            pop_loadcnt — load raw Neuroscan .cnt files
        |
        v
2.  Channel Removal         remove non-EEG channels, retain 64 EEG channels
        |
        v
3.  Band-Pass Filter        1-50 Hz (pop_eegfiltnew), removes DC drift and HF noise
        |
        v
4.  Eye-Movement Correction H-infinity regression on EOG channels (VEO, HEO)
        |
        v
5.  EOG Channel Removal      drop oculomotor channels, 62 channels remain
        |
        v
6.  Channel Locations        assign standard 10-20 electrode coordinates
        |
        v
7.  Common Average Reference subtract mean across channels to reduce common-mode noise
        |
        v
8.  ICA Decomposition        Extended Infomax (runica), blind source separation
        |
        v
9.  Artifact Labelling       ICLabel — classify and remove muscle, eye, heart,
    and Removal              line-noise, and channel-noise components
        |
        v
10. Epoch Segmentation       segment by thinking_inds, isolate imagined-speech trials
        |
        v
11. Sliding Window Framing   windowing with overlap, produces structured trial frames
        |
        v
   Structured .mat Output    (prompts | EEG | windowed data)
```

## Technical Details

| Stage | Method | Parameters |
|---|---|---|
| Bandpass Filter | FIR (pop_eegfiltnew) | 1-50 Hz |
| EOG Correction | H-infinity Regression | mu = 5x10^-3, lambda = 1x10^-5, gamma = 1.5 |
| ICA | Extended Infomax (runica) | Extended mode on |
| Artifact Classification | ICLabel | Auto-label with visual inspection |
| Epoch Reference | `epoch_inds.mat` | `thinking_inds` only |
| Window Size | Sliding window | (verify against code) |
| Window Overlap | 50% | (verify against code) |

> Note: confirm the exact window length and sampling rate against the code before relying on this table. KARA ONE is recorded at 1 kHz, so the sample-count-to-duration figures should be checked.

## Repository Structure

```
KARA-EEG-Preprocessing/
  PP1_preprocessing.m        Main preprocessing pipeline
  split_data.m               Helper: segment EEG by trial indices
  Recordings/
    MM05/
      *.cnt                  Raw EEG recording
      epoch_inds.mat         Trial segmentation indices
      kinect_data/
        labels.txt           Prompt labels
    MM10/ ...
    [other subjects]/
  README.md
```

## Getting Started

### Prerequisites

- MATLAB R2021b or later
- [EEGLAB](https://sccn.ucsd.edu/eeglab/) with the following plugins:
  - `pop_eegfiltnew` (filtering)
  - `pop_hinftv_regression` (H-infinity EOG correction)
  - `pop_runica` / `runica` (ICA decomposition)
  - `ICLabel` (automated artifact classification)
  - `pop_viewprops` (component visualisation)

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

For each subject, the pipeline writes a processed `.mat` file to:

```
Recordings/<SubjectID>/PP-WDATA/
```

Each output contains:

- `EEG_Data.prompts` — cell array of imagined-speech labels
- `EEG_Data.EEG` — segmented EEG trials (thinking phase only)
- `EEG_Data.Data` — full cleaned EEG data
- `all_trials` — windowed and framed trial data ready for feature extraction

## Key Design Decisions

**H-infinity regression for EOG correction.** Unlike plain subtraction, H-infinity regression is a robust adaptive filter that suppresses ocular contamination while preserving neural signal integrity, which matters most at the frontal electrodes.

**Extended Infomax ICA.** Extended mode handles both sub-Gaussian and super-Gaussian sources, making it more reliable across mixed artifact profiles (muscle, cardiac, line noise) than standard Infomax.

**Windowing with 50% overlap.** Short windows capture a meaningful neural epoch while the overlap increases temporal resolution for downstream classifiers without adding excessive redundancy.

## Subjects and Data

| Subject | Notes |
|---------|-------|
| MM05 | Standard recording |
| MM10 | Standard recording |
| MM11 | Standard recording |
| MM16 | Standard recording |
| MM18 | Standard recording |
| MM19 | Standard recording |
| MM21 | Standard recording |
| P02  | Patient subject |

## Roadmap

- [ ] Feature extraction (PSD, CSP, wavelet coefficients)
- [ ] Classification pipeline (SVM, LDA, deep learning)
- [ ] Cross-subject generalisation experiments
- [ ] Real-time BCI inference module

## References

- Zhao, S., & Rudzicz, F. (2015). Classifying phonological categories in imagined and articulated speech. *ICASSP 2015*. (KARA ONE dataset, University of Toronto.)
- Delorme, A., & Makeig, S. (2004). EEGLAB: an open source toolbox for analysis of single-trial EEG dynamics. *Journal of Neuroscience Methods*, 134(1), 9-21.
- Parra, L. C., et al. (2005). Recipes for the linear analysis of EEG. *NeuroImage*, 28(2), 326-341.

## Author

**Iyas Berair**
BSc Electrical Engineering

> This project is part of ongoing work on non-invasive brain-computer interfaces and neural decoding of imagined speech.
