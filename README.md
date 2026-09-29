# Computer Vision — Object Classification and Detection in Satellite Imagery (xView)

This repository contains the **five final notebooks** of the project, organized by experimental block and corresponding to the best-performing configuration found in each case after an extensive experimentation process documented in the project report.

The project addresses two main tasks on the **xView** satellite imagery dataset:

1. **Image classification**
2. **Object detection**

The implementations use **TensorFlow/Keras**, **PyTorch**, and **Ultralytics** depending on the model and task.

## Dataset

We use **xView**, a public large-scale dataset for object detection in satellite imagery captured by the WorldView-3 sensor at 0.3 m spatial resolution.

Two derived subsets are used:

- **xview_recognition** — object-centered crops resized to 224×224 px for classification, containing 13 categories, 18,746 training/validation images, and 2,365 test images.
- **xview_detection** — 640×640 px crops containing multiple objects for detection, with 4 categories (*Small car, Bus, Truck, Building*), 7,606 training images, and 852 test images.

> The dataset is not included in this repository due to its size. It must be downloaded separately, and the dataset paths inside the notebooks must be adapted to the local environment.

## Methodology

- **Classification:** stratified group cross-validation (*Stratified Group K-Fold*, k=10), grouping samples by their original satellite image to reduce the risk of data leakage.
- **Detection:** random 90% training / 10% validation split using a fixed seed for reproducibility.
- Final model performance is evaluated on an **independent test set**, and on **Codabench** where applicable.

## Repository structure

```text
.
├── Notebooks/
│   ├── 1_Best FFNN Model.ipynb
│   ├── 2_Best CNN model without TL.ipynb
│   ├── 3_Best TL Model.ipynb
│   ├── 4_Best Object Detection Model - 1 Phase.ipynb
│   └── 5_Best Object Detection Model - 2 Phases.ipynb
├── .gitignore
├── .python-version
├── README.md
├── requirements.txt
├── setup.ps1
└── setup.sh
```

## Installation

This project uses **Python 3.11**. The expected Python version is also declared in [`.python-version`](.python-version).

The repository includes setup scripts that automatically check for Python 3.11, create a local virtual environment, install the dependencies from `requirements.txt`, verify the installation, and register the environment as a Jupyter kernel.

### Windows (PowerShell)

From the repository root, run:

```powershell
.\setup.ps1
```

After setup, activate the environment with:

```powershell
.\.venv\Scripts\Activate.ps1
```

### Linux / macOS

Make the script executable if needed and run it:

```bash
chmod +x setup.sh
./setup.sh
```

After setup, activate the environment with:

```bash
source .venv/bin/activate
```

### Manual installation

If you prefer not to use the setup scripts, create a Python 3.11 virtual environment and install the dependencies manually:

```bash
python -m venv .venv
pip install --upgrade pip
pip install -r requirements.txt
pip check
```

> A GPU is strongly recommended, especially for the object detection notebooks.

## Notebooks

### 1 — Best FFNN Model

A high-complexity **feed-forward neural network** (~28M parameters) combined with **HOG feature engineering** (*Histogram of Oriented Gradients*) instead of raw pixels. Images are reduced to 64×64 before HOG extraction, with *Batch Normalization* and *Dropout* used for regularization.

The HOG representation explicitly introduces geometric information such as edges and shapes that would otherwise be lost after flattening the image, partially mitigating the spatial limitations of dense networks.

**Test results:**

| Metric | Value |
|---|---:|
| Accuracy | 61.35% |
| Precision (Macro) | 61.60% |
| Recall (Macro) | 59.80% |

### 2 — Best CNN Model without Transfer Learning

**DenseNet-121 trained from scratch** with advanced geometric and photometric data augmentation. Its dense connections encourage feature reuse and improve gradient flow, outperforming the custom CNN architectures and ResNet-34 evaluated during the project.

Moving from a fully connected architecture to a CNN produces a substantial improvement by preserving spatial structure and introducing translation-aware feature extraction.

**Test results:**

| Metric | Value |
|---|---:|
| Accuracy | 81.35% |
| Precision (Macro) | 81.86% |
| Recall (Macro) | 77.76% |

### 3 — Best Transfer Learning Model

**ResNet50V2 pretrained on ImageNet**, trained using a two-phase transfer learning strategy:

- **Phase 1:** frozen backbone with head training using AdamW (`lr=1e-3`).
- **Phase 2:** partial fine-tuning of the upper layers, keeping Batch Normalization layers frozen and using a lower learning rate (`lr≈3e-5`).

DenseNet121, EfficientNetB0, and ResNet50V2 were compared, with ResNet50V2 providing the most balanced overall performance.

**Results:**

| Metric | Value |
|---|---:|
| Mean Accuracy (validation) | 81.28% |
| Accuracy (test — Codabench) | **82.45%** |

> This was the most accurate model in the classification block.

### 4 — Best Object Detection Model · One-Stage

**YOLOv8-Nano (YOLOv8n)** using the **Ultralytics** library and pretrained weights. The final configuration uses a 1024×1024 input resolution, 80 epochs, batch size 2, and a cosine learning-rate scheduler (`cos_lr=True`).

Increasing the input resolution was one of the most influential changes, particularly for detecting small objects in satellite imagery.

**Test results:**

| Metric | Value |
|---|---:|
| mAP | 26.92% |
| Accuracy | 41.46% |
| Precision | 38.21% |
| Recall | 29.56% |

Validation performance: **mAP@50 = 53.54%** and **mAP@50–95 = 26.78%**.

### 5 — Best Object Detection Model · Two-Stage

**Faster R-CNN** with a ResNet-50 backbone and FPN, implemented with `torchvision`. Training was performed in a **Kaggle environment with an NVIDIA Tesla T4 GPU (15 GB)** to overcome local GPU-memory constraints.

The final setup uses 640×640 images, 2000 RPN proposals, *Hard Negative Mining*, the AdamW optimizer, and test-time augmentation with horizontal flipping.

**Results:**

| Metric | Validation | Test |
|---|---:|---:|
| mAP | 30.58% | 25.17% |
| Accuracy | 39.64% | 34.23% |
| Precision | 28.48% | 24.59% |
| Recall | 33.81% | 30.63% |

## Comparative summary

### Classification

| Model | Strategy | Accuracy (test) |
|---|---|---:|
| FFNN (High complexity + HOG) | Dense network + handcrafted features | 61.35% |
| CNN without TL (DenseNet-121) | Training from scratch + augmentation | 81.35% |
| **TL (ResNet50V2)** | **Two-phase transfer learning** | **82.45%** |

### Detection

| Model | Approach | mAP (test) |
|---|---|---:|
| **YOLOv8n (Ultralytics, 1024 px)** | **One-stage** | **26.92%** |
| Faster R-CNN (Kaggle, 640 px) | Two-stage | 25.17% |

## Environment

The main dependencies are listed in [`requirements.txt`](requirements.txt) and include:

- TensorFlow / Keras
- PyTorch / torchvision
- Ultralytics
- NumPy and pandas
- scikit-learn and scikit-image
- Albumentations and OpenCV
- Rasterio and tifffile
- Matplotlib and seaborn
- Jupyter

GPU acceleration is recommended. Local detection experiments were performed with an **NVIDIA GeForce RTX 4070 SUPER (12 GB)**, while the final Faster R-CNN experiments were run on **Kaggle with an NVIDIA Tesla T4 GPU (15 GB)**.

## Key conclusions

- In **classification**, convolutional architectures substantially outperform dense networks because they preserve spatial information. Transfer learning with ResNet50V2 achieved the best classification result, although the improvement over training DenseNet-121 from scratch was relatively small.
- In **object detection**, the YOLOv8 one-stage approach achieved better test mAP than Faster R-CNN under the evaluated configurations and hardware constraints.
- **Input resolution** had a strong impact on small-object detection performance.
- The *Bus* and *Truck* classes remained among the most challenging because of their small size and class imbalance.

## Project authors

This project was developed by:

- Graciela Ezcurra Ferrero
- David Sulleiro Albi
- Alberto García García
