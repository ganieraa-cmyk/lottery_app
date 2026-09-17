import pandas as pd
import firebase_admin
from firebase_admin import credentials, firestore
import os

# ==============================================================================
# CONFIGURATION
# ==============================================================================
EXCEL_FILE = "assets/lottery_data.xlsx"
SHEET_NAME = "Analysis Input"
COLLECTION_NAME = "september_2026_draws"

# You need to download your service account key from the Firebase Console:
# Project Settings > Service Accounts > Generate New Private Key
CREDENTIAL_PATH = "serviceAccountKey.json"
# ==============================================================================

def main():
    # 1. Initialize Firebase Admin SDK
    firebase_connected = False
    if os.path.exists(CREDENTIAL_PATH):
        try:
            cred = credentials.Certificate(CREDENTIAL_PATH)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            firebase_connected = True
            print("✅ Firebase connected successfully!")
        except Exception as e:
            print(f"❌ Error connecting to Firebase: {e}")
    else:
        print(f"⚠️ Warning: '{CREDENTIAL_PATH}' not found.")
        print("   The script will prepare the JSON data but will skip the actual upload.")
        print("   Please download your service account key from Firebase and place it in this folder.\n")

    # 2. Read the Excel file using pandas
    print(f"Reading data from '{EXCEL_FILE}', sheet: '{SHEET_NAME}'...")
    try:
        # Read all columns as strings to preserve leading zeros (e.g., 00743 instead of 743.0)
        df = pd.read_excel(EXCEL_FILE, sheet_name=SHEET_NAME, dtype=str)
    except Exception as e:
        print(f"❌ Error reading Excel file: {e}")
        return

    # 3. Clean the data (Handle NaN and empty values)
    # Fill any NaN (Not a Number) values with an empty string
    df = df.fillna("")
    
    # 4. Convert dataframe to a list of dictionaries (JSON-like format)
    records = df.to_dict(orient="records")
    
    print(f"\nFound {len(records)} records. Preparing to process...")

    uploaded_count = 0
    for i, record in enumerate(records):
        # Ensure all values are clean and Firebase-compatible
        clean_record = {}
        for key, value in record.items():
            # Clean up the column headers (keys)
            clean_key = str(key).strip()
            
            # Clean up the values
            if isinstance(value, str):
                clean_record[clean_key] = value.strip()
            else:
                clean_record[clean_key] = value
                
        # Optional: Print the first 3 records as a sample of the JSON payload
        if i < 3:
            print(f"Sample JSON payload {i+1}: {clean_record}")

        # 5. Upload to Firestore
        if firebase_connected:
            try:
                # We use .add() to auto-generate a document ID. 
                # Alternatively, you could use .document(clean_record['Date']).set(clean_record)
                db.collection(COLLECTION_NAME).add(clean_record)
            except Exception as e:
                print(f"❌ Error uploading record {i}: {e}")
                
        uploaded_count += 1

    print(f"\n✅ Successfully processed {uploaded_count} records.")
    if firebase_connected:
        print(f"🚀 All data uploaded to Firestore collection: '{COLLECTION_NAME}'!")
    else:
        print("ℹ️ Get your serviceAccountKey.json, add it to this folder, and run this script again to upload.")

if __name__ == "__main__":
    main()
