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
- `download_kaggle_split.ps1`: downloads and prepares a train/test split from Kaggle
- `download_wikimedia_dataset.ps1`: helper script for Wikimedia-based image download

## Dataset Source

Kaggle dataset used for the prepared split:

- https://www.kaggle.com/datasets/dhamur/instance-segmentation-simple-dataset

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
  download_kaggle_split.ps1
  download_wikimedia_dataset.ps1
  README.md
```

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
./download_kaggle_split.ps1
```

By default, the script writes paired image and mask files to:

- `Data/Train/images` and `Data/Train/masks`
- `Data/Test/images` and `Data/Test/masks`

