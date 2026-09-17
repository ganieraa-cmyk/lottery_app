import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error
import warnings
warnings.filterwarnings('ignore') # Suppress warnings for clean output

def train_lottery_model(excel_path, sheet_name):
    print("🤖 Initializing Data Science Environment...")
    
    # Load dataset
    df = pd.read_excel(excel_path, sheet_name=sheet_name)
    
    # Define our features (X) and target (y)
    features_cols = ['Date', 'DEAR 1PM MC']
    target_col = 'DEAR 1PM Result'
    
    # Drop rows with missing values in our columns of interest
    df = df.dropna(subset=features_cols + [target_col]).copy()
    
    # Ensure all data is numeric (since ML models require numbers)
    for col in features_cols + [target_col]:
        df[col] = pd.to_numeric(df[col], errors='coerce')
        
    df = df.dropna()
    
    X = df[features_cols]
    y = df[target_col]
    
    print(f"📈 Training Random Forest model on {len(X)} historical records...")
    
    # Split the data into Training (80%) and Testing (20%) sets
    # This helps us evaluate if the model is actually learning or just memorizing
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Initialize Random Forest Regressor
    # We use 100 decision trees to build a "forest" that averages out predictions
    model = RandomForestRegressor(n_estimators=100, random_state=42)
    
    # Train (Fit) the model
    model.fit(X_train, y_train)
    
    # Evaluate the model on test data
    test_predictions = model.predict(X_test)
    mae = mean_absolute_error(y_test, test_predictions)
    
    print("\n📊 MODEL EVALUATION:")
    print(f"Mean Absolute Error (Test Data): {mae:.2f}")
    print("(This indicates how far off, on average, the model's numerical predictions are from the actual results).")
    
    # ---------------------------------------------------------
    # PREDICTING THE NEXT DRAW
    # ---------------------------------------------------------
    # Let's simulate a prediction for the next consecutive day
    last_date = X['Date'].iloc[-1]
    last_mc = X['DEAR 1PM MC'].iloc[-1]
    
    # Assume the next date (looping 31 back to 1)
    next_date = last_date + 1 if last_date < 31 else 1
    
    # In a real scenario, you would input today's actual Machine Code (MC) here once it is announced.
    # For this simulation, we'll use a hypothetical MC similar to recent draws.
    hypothetical_mc = last_mc + 1500  
    
    print(f"\n🔮 PREDICTING NEXT DRAW:")
    print(f"Input Features -> [Date: {int(next_date)}, DEAR 1PM MC: {int(hypothetical_mc)}]")
    
    # The model expects a 2D array, e.g., [[feature1, feature2]]
    next_pred = model.predict([[next_date, hypothetical_mc]])
    
    # Format prediction as a 5-digit string (e.g., 743 -> 00743)
    predicted_result = str(int(next_pred[0])).zfill(5)
    
    print(f"🎯 Predicted DEAR 1PM Result: {predicted_result}")
    
    print("\n" + "="*60)
    print("DISCLAIMER: Lottery draws are independent, random events.")
    print("Machine Learning algorithms are highly effective at finding mathematical")
    print("patterns in historical data, but because lotteries contain extreme noise,")
    print("these predictions are for educational & experimental purposes only.")
    print("="*60)

if __name__ == "__main__":
    train_lottery_model("assets/lottery_data.xlsx", "Analysis Input")
