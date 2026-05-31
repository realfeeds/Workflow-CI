name: Machine Learning CI Workflow

on:
  push:
    branches:
      - main
      - master
  pull_request:
    branches:
      - main
      - master
  workflow_dispatch:

jobs:
  train-model:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v4

    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.12.7'
        cache: 'pip'

    - name: Install Dependencies
      run: |
        python -m pip install --upgrade pip
        pip install mlflow==2.19.0 pandas==2.3.3 scikit-learn==1.8.0 numpy==2.3.3

    - name: Train Machine Learning Model
      run: |
        mlflow run MLProject --env-manager local

    - name: Upload MLflow Runs Artifacts
      uses: actions/upload-artifact@v4
      with:
        name: mlflow-model-artifacts
        path: mlruns/
