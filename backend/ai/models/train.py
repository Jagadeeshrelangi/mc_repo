import os
import joblib
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_recall_fscore_support
from xgboost import XGBClassifier

# Static Encoders
obd_mapping = {
    "None": 0,
    "P0115": 1,
    "P0300": 2,
    "P0562": 3,
    "P0299": 4
}

label_mapping = {
    "Normal": 0,
    "Overheating Engine": 1,
    "Alternator or Battery Failure": 2,
    "Engine Misfire": 3,
    "Low Oil Pressure / Oil Leak": 4
}

reverse_label_mapping = {v: k for k, v in label_mapping.items()}

def train_and_evaluate():
    # Load dataset
    base_dir = os.path.dirname(os.path.dirname(__file__))
    csv_path = os.path.join(base_dir, "data", "vehicle_telemetry.csv")
    
    if not os.path.exists(csv_path):
        raise FileNotFoundError(f"Telemetry CSV not found at {csv_path}. Run generate_data.py first.")
        
    df = pd.read_csv(csv_path)
    
    # Preprocessing
    df["obd_code_encoded"] = df["obd_error_code"].map(obd_mapping)
    df["label_encoded"] = df["fault_label"].map(label_mapping)
    
    # Define features and target
    feature_cols = ["engine_temp", "vibration_level", "battery_voltage", "oil_pressure", "mileage", "obd_code_encoded"]
    X = df[feature_cols]
    y = df["label_encoded"]
    
    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    print("--- Model Training Details ---")
    print(f"Training set: {X_train.shape[0]} rows")
    print(f"Testing set: {X_test.shape[0]} rows\n")
    
    # 1. Train Random Forest
    rf = RandomForestClassifier(n_estimators=100, random_state=42)
    rf.fit(X_train, y_train)
    rf_preds = rf.predict(X_test)
    
    rf_acc = accuracy_score(y_test, rf_preds)
    rf_prec, rf_rec, rf_f1, _ = precision_recall_fscore_support(y_test, rf_preds, average="macro")
    
    print("--- Random Forest Metrics ---")
    print(f"Accuracy:  {rf_acc:.4f}")
    print(f"Precision: {rf_prec:.4f}")
    print(f"Recall:    {rf_rec:.4f}")
    print(f"F1-Score:  {rf_f1:.4f}\n")
    
    # 2. Train XGBoost
    xgb = XGBClassifier(
        n_estimators=100,
        random_state=42,
        eval_metric="mlogloss"
    )
    xgb.fit(X_train, y_train)
    xgb_preds = xgb.predict(X_test)
    
    xgb_acc = accuracy_score(y_test, xgb_preds)
    xgb_prec, xgb_rec, xgb_f1, _ = precision_recall_fscore_support(y_test, xgb_preds, average="macro")
    
    print("--- XGBoost Metrics ---")
    print(f"Accuracy:  {xgb_acc:.4f}")
    print(f"Precision: {xgb_prec:.4f}")
    print(f"Recall:    {xgb_rec:.4f}")
    print(f"F1-Score:  {xgb_f1:.4f}\n")
    
    # Compare and select champion
    if xgb_f1 >= rf_f1:
        print("Selecting XGBoost as Champion Model.")
        best_model = xgb
        best_model_type = "xgboost"
        best_f1 = xgb_f1
    else:
        print("Selecting Random Forest as Champion Model.")
        best_model = rf
        best_model_type = "random_forest"
        best_f1 = rf_f1
        
    # Serialize model and configurations
    output_dir = os.path.join(os.path.dirname(__file__))
    os.makedirs(output_dir, exist_ok=True)
    model_output_path = os.path.join(output_dir, "fault_classifier.joblib")
    
    payload = {
        "model": best_model,
        "model_type": best_model_type,
        "obd_mapping": obd_mapping,
        "label_mapping": label_mapping,
        "reverse_label_mapping": reverse_label_mapping,
        "metrics": {
            "accuracy": xgb_acc if best_model_type == "xgboost" else rf_acc,
            "f1_score": best_f1
        }
    }
    
    joblib.dump(payload, model_output_path)
    print(f"Best model successfully saved to: {model_output_path}")

if __name__ == "__main__":
    train_and_evaluate()
