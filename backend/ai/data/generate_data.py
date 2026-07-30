import os
import pandas as pd
import numpy as np

# Set random seed for reproducibility
np.random.seed(42)

def generate_automotive_dataset(num_rows: int = 1200) -> pd.DataFrame:
    data = []
    
    # Calculate counts per segment
    normal_count = int(num_rows * 0.60)
    overheat_count = int(num_rows * 0.10)
    battery_count = int(num_rows * 0.10)
    misfire_count = int(num_rows * 0.10)
    oil_leak_count = int(num_rows * 0.10)
    
    # Segment 1: Normal Operation
    for _ in range(normal_count):
        engine_temp = np.random.uniform(80.0, 98.0)
        vibration_level = np.random.uniform(0.2, 1.2)
        battery_voltage = np.random.uniform(12.5, 14.4)
        oil_pressure = np.random.uniform(35.0, 55.0)
        mileage = int(np.random.uniform(5000, 200000))
        obd_code = "None"
        label = "Normal"
        data.append([engine_temp, vibration_level, battery_voltage, oil_pressure, mileage, obd_code, label])
        
    # Segment 2: Overheating Engine
    for _ in range(overheat_count):
        engine_temp = np.random.uniform(103.0, 128.0)
        vibration_level = np.random.uniform(0.5, 1.8)
        battery_voltage = np.random.uniform(12.0, 14.2)
        oil_pressure = np.random.uniform(20.0, 50.0)
        mileage = int(np.random.uniform(15000, 240000))
        obd_code = np.random.choice(["P0115", "None"], p=[0.85, 0.15])
        label = "Overheating Engine"
        data.append([engine_temp, vibration_level, battery_voltage, oil_pressure, mileage, obd_code, label])
        
    # Segment 3: Alternator or Battery Failure
    for _ in range(battery_count):
        engine_temp = np.random.uniform(80.0, 95.0)
        vibration_level = np.random.uniform(0.2, 1.2)
        battery_voltage = np.random.uniform(9.2, 11.6)
        oil_pressure = np.random.uniform(30.0, 55.0)
        mileage = int(np.random.uniform(10000, 220000))
        obd_code = np.random.choice(["P0562", "None"], p=[0.80, 0.20])
        label = "Alternator or Battery Failure"
        data.append([engine_temp, vibration_level, battery_voltage, oil_pressure, mileage, obd_code, label])
        
    # Segment 4: Engine Misfire
    for _ in range(misfire_count):
        engine_temp = np.random.uniform(85.0, 105.0)
        vibration_level = np.random.uniform(2.2, 4.8)
        battery_voltage = np.random.uniform(12.0, 14.2)
        oil_pressure = np.random.uniform(30.0, 55.0)
        mileage = int(np.random.uniform(20000, 250000))
        obd_code = np.random.choice(["P0300", "None"], p=[0.75, 0.25])
        label = "Engine Misfire"
        data.append([engine_temp, vibration_level, battery_voltage, oil_pressure, mileage, obd_code, label])
        
    # Segment 5: Low Oil Pressure / Oil Leak
    for _ in range(oil_leak_count):
        engine_temp = np.random.uniform(85.0, 112.0)
        vibration_level = np.random.uniform(0.5, 2.0)
        battery_voltage = np.random.uniform(12.0, 14.2)
        oil_pressure = np.random.uniform(9.5, 19.5)
        mileage = int(np.random.uniform(30000, 250000))
        obd_code = np.random.choice(["P0299", "None"], p=[0.50, 0.50])
        label = "Low Oil Pressure / Oil Leak"
        data.append([engine_temp, vibration_level, battery_voltage, oil_pressure, mileage, obd_code, label])
        
    columns = ["engine_temp", "vibration_level", "battery_voltage", "oil_pressure", "mileage", "obd_error_code", "fault_label"]
    df = pd.DataFrame(data, columns=columns)
    
    # Shuffle dataset
    df = df.sample(frac=1).reset_index(drop=True)
    return df

if __name__ == "__main__":
    df = generate_automotive_dataset()
    
    # Define output path
    output_dir = os.path.join(os.path.dirname(__file__))
    os.makedirs(output_dir, exist_ok=True)
    output_file = os.path.join(output_dir, "vehicle_telemetry.csv")
    
    df.to_csv(output_file, index=False)
    print(f"Dataset successfully compiled: {output_file} ({df.shape[0]} rows generated)")
