import pandas as pd
from collections import Counter

def calculate_transitional_probability(excel_path, sheet_name, mc_col, res_col, target_mc_digit):
    print(f"Analyzing transitional probability from '{mc_col}' to '{res_col}'...")
    
    # Read as string to prevent 5 being read as 5.0
    df = pd.read_excel(excel_path, sheet_name=sheet_name, dtype=str)
    
    # Drop rows where either column is missing
    df = df.dropna(subset=[mc_col, res_col])
    
    # Clean the data (remove '.0' if it accidentally got parsed as a float)
    df[mc_col] = df[mc_col].str.replace('.0', '', regex=False).str.strip()
    df[res_col] = df[res_col].str.replace('.0', '', regex=False).str.strip()
    
    # Filter historical data where MC Last exactly matches our target digit
    filtered_df = df[df[mc_col] == str(target_mc_digit)]
    
    total_occurrences = len(filtered_df)
    
    if total_occurrences == 0:
        print(f"\nNo historical records found where '{mc_col}' was '{target_mc_digit}'.")
        return
        
    print(f"\nFound {total_occurrences} historical draws where {mc_col} was '{target_mc_digit}'.")
    
    # Count the outcomes in the Result column
    outcomes = filtered_df[res_col].tolist()
    outcome_counts = Counter(outcomes)
    
    print("\n📊 TRANSITIONAL PROBABILITIES (6PM Result Last):")
    for digit, count in outcome_counts.most_common():
        probability = (count / total_occurrences) * 100
        print(f"Digit {digit}: {probability:.2f}% chance ({count} times)")
        
    most_likely = outcome_counts.most_common(1)[0]
    print(f"\n🔮 PREDICTION: Based on historical data, if today's Machine last digit is {target_mc_digit},")
    print(f"the most likely Result last digit will be '{most_likely[0]}' ({most_likely[1]}/{total_occurrences} times).")

if __name__ == "__main__":
    # Feel free to change target_mc_digit to predict other scenarios!
    calculate_transitional_probability(
        excel_path="assets/lottery_data.xlsx",
        sheet_name="Analysis Input",
        mc_col="6PM MC Last",
        res_col="6PM Result Last",
        target_mc_digit="5"
    )
