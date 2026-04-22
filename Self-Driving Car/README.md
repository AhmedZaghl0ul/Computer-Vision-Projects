# Self-Driving Car Perception Pipeline

This repository contains a Jupyter Notebook (`Self_Driving_Cars.ipynb`) focused on building a perception pipeline for self-driving cars, specifically utilizing computer vision and deep learning techniques to process road images. 

## Overview
The primary goal of this project is to explore and implement models for autonomous vehicle applications, such as lane detection and object recognition. The notebook incorporates data loading, exploratory data analysis (EDA), data preprocessing, and model training using modern computer vision libraries.

## Dataset
The notebook utilizes the **TuSimple** dataset (`manideep1108/tusimple`), a widely used benchmark for lane detection tasks. The dataset contains a variety of road conditions, lighting, and weather, making it ideal for training robust perception models.

## Dependencies
To execute the notebook successfully, the following libraries and packages are required:
- Python 3.x
- [Ultralytics (YOLO)](https://github.com/ultralytics/ultralytics) (for advanced object detection)
- TensorFlow & Keras
- OpenCV (`cv2`)
- NumPy & Pandas
- Matplotlib (for visualization)
- Scikit-learn
- `kagglehub` (for direct dataset downloading)

## Notebook Structure
1. **Environment Setup & Data Loading:** Installs necessary packages (e.g., `ultralytics`) and downloads the TuSimple dataset from Kaggle directly into the working directory.
2. **Exploratory Data Analysis (EDA):** Analyzes the directory structure of the dataset and uses `matplotlib` to visualize sample road frames.
3. **Data Preprocessing:** Prepares the images and label data to be fed into the deep learning models.
4. **Model Architecture & Training:** Constructs and trains neural networks (via TensorFlow/Keras and YOLO architectures) to perform critical driving perception tasks.

## Usage
1. Ensure your environment has GPU support configured (the notebook is optimized for execution on setups like Google Colab with a T4 GPU).
2. Install the required dependencies (some lines in the notebook handle this automatically via `!pip install`).
3. Run the notebook sequentially from top to bottom.

## Future Enhancements
- Fine-tuning models for improved real-time inference speed.
- Implementing tracking algorithms for bounding boxes across video frames.
- Integrating semantic segmentation layers for comprehensive road scene understanding.
