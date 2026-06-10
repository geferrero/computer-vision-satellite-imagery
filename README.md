#  Computer Vision — Object Classification and Detection in Satellite Imagery (xView)

Final project for the **Computer Vision** course of the *Master's Degree in Artificial Intelligence* (UPM — ETSIINF).

This repository contains the **five final notebooks**, one per project block, corresponding to the best configuration found in each case after an extensive experimental process (documented in the report). The goal is to solve two tasks on the **xView** dataset using deep learning with TensorFlow/Keras, PyTorch, and Ultralytics:

1. **Image recognition** (classification)
2. **Object detection**

## Dataset

We use **xView**, a public large-scale dataset for object detection in satellite imagery (WorldView-3 sensor, 0.3 m spatial resolution). Two derived subsets are used:

- **xview_recognition** (classification): object-centered crops resized to 224×224 px, 13 categories, 18,746 training/validation images and 2,365 test images.
- **xview_detection** (detection): 640×640 px crops with multiple objects, 4 categories (*Small car, Bus, Truck, Building*), 7,606 training images and 852 test images.

> The dataset is not included in the repository due to its size. You need to download it and adjust the paths inside each notebook.

## Methodology

- **Classification:** stratified group cross-validation (*Stratified Group K-Fold*, k=10), grouping by the original satellite image to prevent data leakage.
- **Detection:** random 90% train / 10% validation split with a fixed seed for reproducibility.
- Final evaluation is performed on the **independent test set** (and on **Codabench** where applicable).

## Repository structure

```
.
├── 1_Mejor Modelo FFNN.ipynb
├── 2_Mejor Modelo CNN sin TL.ipynb
├── 3_Mejor Modelo TL.ipynb
├── 4_Mejor Modelo Object Detection - 1 Fase.ipynb
├── 5_Mejor Modelo Object Detection - 2 Fases.ipynb
└── README.md
```

---

## Notebooks

### 1 — Best FFNN Model

A high-complexity **feed-forward (dense) network** (~28M parameters) combined with **HOG feature engineering** (*Histogram of Oriented Gradients*) instead of raw pixels. Input reduced to 64×64 before HOG; regularization via *Batch Normalization* + *Dropout*.

The HOG strategy explicitly injects geometric information (edges and shapes) that the `Flatten` layer destroyed, partially solving the "spatial blindness" of dense networks (e.g., doubling the recall of the *Truck* class).

**Test results:**

| Metric | Value |
|---|---|
| Accuracy | 61.35% |
| Precision (Macro) | 61.60% |
| Recall (Macro) | 59.80% |

---

### 2 — Best CNN Model without Transfer Learning

**DenseNet-121 trained from scratch** with **advanced data augmentation** (geometric + photometric). The dense connections promote feature reuse and improved gradient flow, outperforming ResNet-34 and the custom CNNs designed in the project.

Moving from FFNN to CNN yields a jump of more than 15 percentage points by introducing translation invariance and spatial coherence.

**Test results:**

| Metric | Value |
|---|---|
| Accuracy | 81.35% |
| Precision (Macro) | 81.86% |
| Recall (Macro) | 77.76% |

---

### 3 — Best Transfer Learning Model

**ResNet50V2 pretrained on ImageNet**, with a two-phase *transfer learning* scheme:

- **Phase 1:** frozen backbone, head training (AdamW, lr=1e-3).
- **Phase 2:** partial fine-tuning of the higher layers (BatchNorm frozen, lr≈3e-5).

DenseNet121, EfficientNetB0, and ResNet50V2 were compared; the latter proved the most balanced and accurate, especially on the hardest classes.

**Results:**

| Metric | Value |
|---|---|
| Mean Accuracy (validation) | 81.28% |
| Accuracy (test — Codabench) | **82.45%** |

> Most accurate model of the entire classification block.

---

### 4 — Best Object Detection Model · One-Stage

**YOLOv8-Nano (YOLOv8n)** with the **Ultralytics** library (PyTorch), starting from pretrained weights. Key configuration: input resolution increased to **1024×1024**, 80 epochs, *batch size* 2, and cosine *scheduler* (`cos_lr=True`).

Increasing the resolution was the most decisive factor (over architectural changes), notably improving the detection of small objects.

**Test results:**

| Metric | Value |
|---|---|
| mAP | 26.92% |
| Accuracy | 41.46% |
| Precision | 38.21% |
| Recall | 29.56% |

(Validation: mAP@50 = 53.54% · mAP@50–95 = 26.78%.)

---

### 5 — Best Object Detection Model · Two-Stage

**Faster R-CNN** (ResNet-50 backbone + FPN, `torchvision`), trained in a **Kaggle environment (GPU Tesla T4, 15 GB)** to overcome the memory limitations of the local setup. Configuration: 640×640 resolution, 2000 RPN proposals, *Hard Negative Mining*, AdamW optimizer, and TTA with horizontal flip.

**Results:**

| Metric | Validation | Test |
|---|---|---|
| mAP | 30.58% | 25.17% |
| Accuracy | 39.64% | 34.23% |
| Precision | 28.48% | 24.59% |
| Recall | 33.81% | 30.63% |

---

## Comparative summary

### Classification

| Model | Strategy | Accuracy (test) |
|---|---|---|
| FFNN (High complexity + HOG) | Dense network + manual features | 61.35% |
| CNN without TL (DenseNet-121) | From scratch + augmentation | 81.35% |
| **TL (ResNet50V2)** | **Two-phase transfer learning** | **82.45%** |

### Detection

| Model | Approach | mAP (test) |
|---|---|---|
| **YOLOv8n (Ultralytics, 1024px)** | **One-stage** | **26.92%** |
| Faster R-CNN (Kaggle, 640px) | Two-stage | 25.17% |

## Requirements and environment

- Python 3.x
- **Classification:** TensorFlow / Keras, NumPy, scikit-learn, scikit-image (HOG), Matplotlib
- **Detection:** PyTorch, torchvision, Ultralytics, KerasCV, Albumentations
- GPU recommended. Detection requires high VRAM: local tests were run on an **NVIDIA GeForce RTX 4070 SUPER (12 GB)** and, for Faster R-CNN, on **Kaggle with an NVIDIA Tesla T4 GPU (15 GB)**.

## Key conclusions

- In **classification**, CNNs structurally outperform dense networks; *transfer learning* (ResNet50V2) gives the best result, although the improvement over training from scratch is modest (+1.1%), confirming the specificity of the satellite domain relative to ImageNet.
- In **detection**, **single-stage models (YOLOv8)** proved more viable and effective than Faster R-CNN under the hardware constraints. **Input resolution** had more impact than architectural changes.
- The *Bus* and *Truck* classes remain the most difficult, due to their small size and the dataset's strong imbalance.
