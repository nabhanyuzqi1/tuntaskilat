import csv

def calc_sus(row):
    q_scores = []
    # indices 2 to 11 are Q1 to Q10
    try:
        q_vals = [int(row[i]) for i in range(2, 12)]
    except ValueError:
        return None
    
    for i, val in enumerate(q_vals):
        q_num = i + 1
        if q_num % 2 != 0: # odd
            q_scores.append(val - 1)
        else: # even
            q_scores.append(5 - val)
            
    return sum(q_scores) * 2.5

scores = []
with open("/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/Evaluasi Purwarupa Aplikasi Tuntaskilat (Usability Testing)-2.csv", newline='', encoding='utf-8') as f:
    reader = csv.reader(f)
    next(reader) # skip header
    for row in reader:
        score = calc_sus(row)
        if score is not None:
            scores.append(score)

avg_score = sum(scores) / len(scores)
print(f"Total respondents: {len(scores)}")
print(f"Average SUS Score: {avg_score}")
