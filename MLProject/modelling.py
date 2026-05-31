import os
import pandas as pd
import mlflow
import mlflow.sklearn
import urllib.request

from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score
)

# Set MLflow Tracking URI
# Jika berjalan di GitHub Actions (CI), gunakan local storage default agar tidak error
if os.environ.get("CI") == "true":
    print("Running in CI environment. Using default local MLflow tracking.")
else:
    mlflow.set_tracking_uri("http://127.0.0.1:5000/")

# Create a new MLflow Experiment (hanya jika tidak dijalankan lewat 'mlflow run')
if "MLFLOW_RUN_ID" not in os.environ:
    mlflow.set_experiment("Modelling Identifikasi Diabetes")

# Enable MLflow autolog
mlflow.sklearn.autolog()

# Load dataset using robust paths relative to this script's directory
script_dir = os.path.dirname(os.path.abspath(__file__))
train_path = os.path.join(script_dir, 'diabetes_preprocessing', 'diabetes_train_preprocessing.csv')
test_path = os.path.join(script_dir, 'diabetes_preprocessing', 'diabetes_test_preprocessing.csv')

train_df = pd.read_csv(train_path)
test_df = pd.read_csv(test_path)

# Split features and target
X_train = train_df.drop("Outcome", axis=1)
y_train = train_df["Outcome"]

X_test = test_df.drop("Outcome", axis=1)
y_test = test_df["Outcome"]

# Start MLflow run
with mlflow.start_run():

    # Initialize model
    model = LogisticRegression(random_state=42)

    # Train model
    model.fit(X_train, y_train)

    # Prediction
    y_pred = model.predict(X_test)

    # Evaluation metrics
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)

    # Print metrics
    print(f"Accuracy  : {accuracy:.4f}")
    print(f"Precision : {precision:.4f}")
    print(f"Recall    : {recall:.4f}")
    print(f"F1 Score  : {f1:.4f}")
