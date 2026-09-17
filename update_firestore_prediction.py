import firebase_admin
from firebase_admin import credentials, firestore
import sys
import os

# ==========================================
# CONFIGURATION
# ==========================================
CREDENTIAL_PATH = "serviceAccountKey.json"
COLLECTION_NAME = "september_2026_draws"
DOCUMENT_ID = "16"
# ==========================================

def update_firestore_record():
    print("Connecting to Firebase...")
    
    # 1. Verify the Service Account Key exists
    if not os.path.exists(CREDENTIAL_PATH):
        print(f"\n❌ Error: '{CREDENTIAL_PATH}' was not found in this folder.")
        print("Please ensure you have downloaded your Firebase Service Account key and named it correctly.")
        sys.exit(1)
        
    try:
        # 2. Initialize Firebase (Check if already initialized to prevent errors)
        if not firebase_admin._apps:
            cred = credentials.Certificate(CREDENTIAL_PATH)
            firebase_admin.initialize_app(cred)
            
        db = firestore.client()
        
        # 3. Define the exact fields and values to update/add
        update_payload = {
            "DEAR 1PM Result": 76988,
            "AI_Prediction": 45298,
            "AI_Error_Margin": 31690
        }
        
        # 4. Target the specific document
        doc_ref = db.collection(COLLECTION_NAME).document(DOCUMENT_ID)
        
        # 5. Perform the update
        # Using .set(..., merge=True) is safer than .update() because it will automatically
        # create the document if it doesn't already exist, while preserving any other existing fields!
        doc_ref.set(update_payload, merge=True)
        
        print(f"\n✅ SUCCESS! Document ID '{DOCUMENT_ID}' in '{COLLECTION_NAME}' was successfully updated.")
        print(f"Fields pushed to database: {update_payload}")
        
    except Exception as e:
        print(f"\n❌ Failed to update Firestore database. Error details: {e}")

if __name__ == "__main__":
    update_firestore_record()
