import pandas as pd
from collections import Counter
import random
import sys

def predict_next_draw(excel_path, sheet_name, column_name):
    print(f"Analyzing '{column_name}' from {excel_path}...")
    try:
        df = pd.read_excel(excel_path, sheet_name=sheet_name, dtype=str)
    except Exception as e:
        print(f"Error reading file: {e}")
        sys.exit(1)
        
    # Drop empty values
    results = df[column_name].dropna()
    
    # 1. Frequency Analysis
    all_digits = []
    for res in results:
        # Clean string (e.g., if pandas parsed it as "743.0", convert to "00743" by padding, though dtype=str usually prevents this.
        # But looking at the user's previous logs, it lacked leading zeros sometimes. 
        # We will strip '.0' and pad to 5 digits just in case it's a standard 5-digit lottery.)
        clean_res = str(res).replace('.0', '').strip()
        # Assume 5 digit standard for DEAR lotteries
        clean_res = clean_res.zfill(5)
        all_digits.extend(list(clean_res))
        
    digit_counts = Counter(all_digits)
    
    print("\n📊 HISTORICAL DIGIT FREQUENCIES:")
    most_common_digits = []
    for digit, count in digit_counts.most_common():
        print(f"Digit {digit}: appeared {count} times")
        most_common_digits.append(digit)
        
    # 2. Prediction Algorithm
    print("\n🔮 PREDICTING NEXT DRAW (Top 3 Likely Numbers):")
    predictions = []
    
    # Algorithm A: The 'Super Frequency' Number
    # Formed by the top 5 most frequent digits in descending order of frequency
    top_5 = "".join(most_common_digits[:5])
    predictions.append(top_5)
    
    # Algorithm B & C: Weighted Random Generation
    # Generates a number where digits that appeared more historically have a proportionally 
    # higher chance of being picked for each slot.
    population = list(digit_counts.keys())
    weights = list(digit_counts.values())
    
    for _ in range(2):
        pred = ""
        for _ in range(5): # 5 digits per number
            chosen = random.choices(population, weights=weights, k=1)[0]
            pred += chosen
        predictions.append(pred)
        
    return predictions

if __name__ == "__main__":
    predictions = predict_next_draw("assets/lottery_data.xlsx", "Analysis Input", "DEAR 1PM Result")
    
    print("\nTop 3 Predicted Numbers:")
    print(f"⭐ 1. {predictions[0]} (Based on absolute highest frequency digits)")
    print(f"⭐ 2. {predictions[1]} (Based on historical weighted probability)")
    print(f"⭐ 3. {predictions[2]} (Based on historical weighted probability)")
