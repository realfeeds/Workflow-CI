name: CI/CD MLflow

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

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

      # Fix MLflow absolute paths for Linux runner
      - name: Fix MLflow absolute paths for Linux runner
        run: |
          find . -name "meta.yaml" -exec sed -i "s|file:///C:/Users/user/OneDrive/Documents/GitHub%20Projects/Workflow-CI|file://$GITHUB_WORKSPACE|g" {} + 2>/dev/null || true

      # Setup Python 3.12.7
      - name: Set up Python 3.12.7
        uses: actions/setup-python@v4
        with:
          python-version: "3.12.7"
      
      # Check Env Variables
      - name: Check Env
        run: |
          echo $CSV_URL

      # Install mlflow and dependencies
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install mlflow==2.19.0 pandas==2.3.3 scikit-learn==1.8.0 numpy==2.3.3
          
      # Run as a mlflow project
      - name: Run mlflow project
        run: |
          mlflow run MLProject --env-manager=local 
      
      # Get latest run_id
      - name: Get latest MLflow run_id
        run: |
          RUN_ID=$(ls -td mlruns/0/*/ | head -n 1 | cut -d'/' -f3)
          echo "RUN_ID=$RUN_ID" >> $GITHUB_ENV
          echo "Latest run_id: $RUN_ID"
          
      # Build Docker Model
      - name: Build Docker Model
        run: |
          mlflow models build-docker --model-uri "runs:/$RUN_ID/model" --name "diabetes-model" --env-manager=local

      # Login to Docker Hub
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_ACCESS_TOKEN }}

      # Tag the Docker image
      - name: Tag Docker Image
        run: |
          docker tag diabetes-model ${{ secrets.DOCKER_HUB_USERNAME }}/diabetes-model:latest

      # Push Docker image to Docker Hub
      - name: Push Docker Image
        run: |
          docker push ${{ secrets.DOCKER_HUB_USERNAME }}/diabetes-model:latest

      # Upload MLflow Runs Artifacts (Kriteria 3)
      - name: Upload to GitHub
        uses: actions/upload-artifact@v4
        with:
          name: mlflow-model-artifacts
          path: |
            mlruns/
            MLProject/mlruns/

      # Commit and Push MLflow Runs to Repository (Kriteria 3)
      - name: Commit and Push MLflow Runs to Repository
        run: |
          find mlruns/ -name "meta.yaml" -exec sed -i "s|file://$GITHUB_WORKSPACE|file:///C:/Users/user/OneDrive/Documents/GitHub%20Projects/Workflow-CI|g" {} +
          git config --global user.name "github-actions[bot]"
          git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add mlruns/
          git commit -m "chore: save training artifacts from CI workflow [skip ci]" || echo "No changes to commit"
          git push
