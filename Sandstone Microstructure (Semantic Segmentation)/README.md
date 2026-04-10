# Sandstone Microstructure (Semantic Segmentation)

This project focuses on semantic segmentation workflows for sandstone microstructure imagery.

## Project Contents

- `Data/Train/images`: 30 training images
- `Data/Train/masks`: 30 training masks
- `Data/Test/images`: 20 testing images
- `Data/Test/masks`: 20 testing masks
- `Data/Train/sources_train.csv`: mapping file for selected training samples
- `Data/Test/sources_test.csv`: mapping file for selected testing samples
- `code.ipynb`: notebook for experimentation and model development
- `RF_MODEL.pickle`: saved model artifact

## Dataset Source

Kaggle dataset used for the prepared split:

- https://www.kaggle.com/datasets/dhamur/instance-segmentation-simple-dataset

## Model Creation Structure

The model was built using a hybrid pipeline: CNN feature extraction (VGG19) + Random Forest pixel classification.

### 1. Data Preparation

- Training images loaded from `Data/Train/images`.
- Training masks loaded from `Data/Train/masks`.
- Images resized to `256 x 256` and converted with OpenCV before feature extraction.

### 2. Feature Extractor (CNN Backbone)

- Backbone: `VGG19(include_top=False, input_shape=(256,256,3))`
- All VGG19 layers frozen (`layer.trainable = False`).
- Feature model output taken from `block1_conv2`:
  - `new_model = Model(inputs=model.input, outputs=model.get_layer("block1_conv2").output)`
- Feature shape per image: `256 x 256 x 64`.

### 3. Pixel-Wise Classifier (Random Forest)

- Extracted features reshaped to 2D pixel-feature vectors:
  - `X = features.reshape(-1, features.shape[3])`
- Labels flattened from masks:
  - `Y = y_train.reshape(-1)`
- If label length mismatch occurs, the notebook uses one channel:
  - `Y_fixed = y_train[..., 0].reshape(-1)`
- Background pixels removed:
  - `dataset = dataset[dataset['label'] != 0]`
- Final model configuration used for training:

```python
RandomForestClassifier(
    n_estimators=20,
    max_depth=12,
    max_samples=0.5,
    random_state=42,
    n_jobs=-1
)
```

- Training set is memory-capped to a random subset of up to `200000` samples.

### 4. Inference Flow

- Load test image -> resize to `256 x 256` -> extract VGG features.
- Reshape features to pixel vectors.
- Predict class per pixel with the trained Random Forest.
- Reshape predictions back to `256 x 256` mask.
- Save output segmentation as `test.jpg`.

### Pipeline Summary

`Input Image (256x256x3) -> VGG19 block1_conv2 features (256x256x64) -> Flatten pixels -> RandomForestClassifier -> Segmentation Mask (256x256)`

## Folder Structure

```text
Sandstone Microstructure (Semantic Segmentation)/
  Data/
    Train/
      images/
      masks/
      sources_train.csv
    Test/
      images/
      masks/
      sources_test.csv
  code.ipynb
  RF_MODEL.pickle

  README.md
```

By default, the script writes paired image and mask files to:

- `Data/Train/images` and `Data/Train/masks`
- `Data/Test/images` and `Data/Test/masks`
