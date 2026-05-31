name: CI/CD MLflow

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

env:
  CSV_URL: "MLProject/diabetes_preprocessing/diabetes_train_preprocessing.csv"
  TARGET_VAR: "Outcome"

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: write

    steps:
      # Checks-out your repository under $GITHUB_WORKSPACE
      - uses: actions/checkout@v3

      - name: Fix MLflow absolute paths for Linux runner
        run: |
          find . -name "meta.yaml" -exec sed -i "s|file:///C:/Users/user/OneDrive/Documents/GitHub%20Projects/Workflow-CI|file://$GITHUB_WORKSPACE|g" {} + 2>/dev/null || true

      - name: Set up Python 3.12.7
        uses: actions/setup-python@v4
        with:
          python-version: "3.12.7"

      - name: Check Env
        run: |
          echo $CSV_URL

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mlflow==2.19.0 pandas==2.3.3 scikit-learn==1.8.0 numpy==2.3.3

      - name: Run mlflow project
        run: |
          mlflow run MLProject --env-manager=local

      - name: Get latest MLflow run_id
        run: |
          RUN_ID=$(ls -td mlruns/0/*/ | head -n 1 | cut -d'/' -f3)
          echo "RUN_ID=$RUN_ID" >> $GITHUB_ENV
          echo "Latest run_id: $RUN_ID"

      - name: Build Docker Model
        run: |
          mlflow models build-docker --model-uri "runs:/$RUN_ID/model" --name "diabetes-model"

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      - name: Tag Docker Image
        run: |
          docker tag diabetes-model ${{ secrets.DOCKER_HUB_USERNAME }}/diabetes-model:latest

      - name: Push Docker Image
        run: |
          docker push ${{ secrets.DOCKER_HUB_USERNAME }}/diabetes-model:latest

      - name: Upload MLflow Runs Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: mlflow-model-artifacts
          path: |
            mlruns/
            MLProject/mlruns/

      - name: Commit and Push MLflow Runs to Repository
        run: |
          # Ubah kembali jalur mutlak ke format Windows lokal sebelum di-commit agar lokal tetap kompatibel
          find mlruns/ -name "meta.yaml" -exec sed -i "s|file://$GITHUB_WORKSPACE|file:///C:/Users/user/OneDrive/Documents/GitHub%20Projects/Workflow-CI|g" {} +
          git config --global user.name "github-actions[bot]"
          git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add mlruns/
          git commit -m "chore: save training artifacts from CI workflow [skip ci]" || echo "No changes to commit"
          git push
