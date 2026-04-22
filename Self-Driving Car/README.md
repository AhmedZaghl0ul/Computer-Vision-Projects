# Self-Driving Car — Lane Detection with U-Net

A deep learning project that performs **lane detection** on road images using a **U-Net semantic segmentation** model trained on the **TuSimple** lane detection benchmark dataset.

---

## Overview

This project tackles one of the fundamental challenges in autonomous driving: **detecting lane markings** from camera images. A custom **U-Net** architecture is built from scratch using **TensorFlow/Keras** to predict binary lane masks from road images. The predicted masks are then overlaid on the original images to visualize detected lanes.

---

## Architecture

The model uses a **U-Net** encoder-decoder architecture with skip connections:

| Stage | Layer Type | Filters | Output Shape |
|-------|-----------|---------|--------------|
| **Encoder Block 1** | 2× Conv2D (3×3, ReLU) + MaxPool | 64 | 128×128×64 |
| **Encoder Block 2** | 2× Conv2D (3×3, ReLU) + MaxPool | 128 | 64×64×128 |
| **Bottleneck** | 2× Conv2D (3×3, ReLU) | 256 | 64×64×256 |
| **Decoder Block 1** | Conv2DTranspose + Concat + 2× Conv2D | 128 | 128×128×128 |
| **Decoder Block 2** | Conv2DTranspose + Concat + 2× Conv2D | 128 | 256×256×128 |
| **Output** | Conv2D (1×1, Sigmoid) | 1 | 256×256×1 |

> **Total Parameters:** ~2,047,361 (7.81 MB)

---

## Dataset

- **Source:** [TuSimple Lane Detection Dataset](https://www.kaggle.com/datasets/manideep1108/tusimple) (via Kaggle)
- **Size:** ~21.6 GB
- **Structure:**
  - `train_set/` — Training clips organized by date folders (`0313-1`, `0313-2`, `0531`, `0601`)
  - `test_set/` — Test clips organized by date folders (`0530`, `0531`, `0601`)
  - JSON label files containing lane point annotations and `h_samples`

### Data Preprocessing

1. **Mask Generation:** Lane annotations (x-coordinates at given y-samples) are converted into binary segmentation masks using `cv2.polylines`.
2. **Image/Mask Pairing:** Each road image is paired with its corresponding binary lane mask.
3. **Resizing:** All images and masks are resized to **256×256** pixels.
4. **Normalization:** Pixel values are normalized to the **[0, 1]** range.
5. **Train/Val Split:** An **80/20** train/validation split is applied (~3,626 total pairs → 182 training batches, 46 validation batches at batch size 16).

---

## Training Configuration

| Parameter | Value |
|-----------|-------|
| **Optimizer** | Adam |
| **Loss Function** | Binary Cross-Entropy |
| **Metric** | Accuracy |
| **Epochs** | 10 |
| **Batch Size** | 16 |
| **Image Size** | 256 × 256 × 3 |
| **Callbacks** | ModelCheckpoint, EarlyStopping (patience=3), ReduceLROnPlateau |

### Training Results

| Epoch | Train Loss | Train Acc | Val Loss | Val Acc |
|-------|-----------|-----------|----------|---------|
| 1 | 0.0898 | 97.95% | 0.0643 | 98.10% |
| 5 | 0.0395 | 98.32% | 0.0386 | 98.35% |
| 9 | 0.0352 | 98.38% | 0.0354 | 98.40% |
| 10 | 0.0349 | 98.39% | 0.0360 | 98.38% |

> Best model saved at **Epoch 9** with `val_loss = 0.03538`.

---

## Quick Start

### Prerequisites

```
Python 3.x
TensorFlow / Keras
OpenCV (cv2)
NumPy
Matplotlib
scikit-learn
Ultralytics (for YOLO utilities, optional)
kagglehub
```

### Running the Notebook

1. Open `Self_Driving_Cars.ipynb` in **Google Colab** (recommended for GPU access — T4 GPU used during training).
2. The notebook will automatically download the TuSimple dataset via `kagglehub`.
3. Follow the cells sequentially:
   - **Load Data** — Downloads and explores the TuSimple dataset
   - **EDA** — Exploratory data analysis of the dataset structure
   - **Prepare Data** — Generates lane masks, creates train/val splits, builds `tf.data` pipelines
   - **Model Building** — Defines, compiles, and trains the U-Net model
   - **Visualizations** — Loads the best model and visualizes predictions

### Inference Example

```python
from tensorflow.keras import models
import tensorflow as tf
import numpy as np
import cv2

# Load the trained model
model = models.load_model("model.keras")

# Preprocess an image
image = tf.io.read_file("path/to/road_image.jpg")
image = tf.image.decode_jpeg(image, channels=3)
image = tf.image.resize(image, [256, 256]) / 255.0

# Predict lane mask
pred = model.predict(tf.expand_dims(image, axis=0))[0]
pred_mask = (pred > 0.5).astype(np.float32)

# Overlay on original
overlay = np.zeros_like(image.numpy())
overlay[:, :, 0] = pred_mask[:, :, 0]
result = cv2.addWeighted(image.numpy(), 1.0, overlay, 0.7, 0)
```

---

## Project Structure

```
Self-Driving Car/
├── Self_Driving_Cars.ipynb   # Main notebook (training + inference)
├── model.keras               # Trained U-Net model weights
└── README.md                 # Project documentation
```

---

## Tech Stack

- **Deep Learning Framework:** TensorFlow / Keras
- **Architecture:** U-Net (custom implementation)
- **Computer Vision:** OpenCV
- **Dataset Management:** KaggleHub
- **Training Environment:** Google Colab (T4 GPU)

---

## License

This project is for educational and research purposes.
