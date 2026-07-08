import docx

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev18.docx"
doc = docx.Document(doc_path)

wireframes = []
ideasi = []
definisi = []

for i, p in enumerate(doc.paragraphs):
    text = p.text.lower()
    if 'wireframe' in text:
        wireframes.append(f"Para {i}: {p.text}")
    if 'ideasi' in text:
        ideasi.append(f"Para {i}: {p.text}")
    if 'definisi' in text and 'tahap' in text:
        definisi.append(f"Para {i}: {p.text}")
        
print("=== WIREFRAME ===")
for x in wireframes: print(x)
print("\n=== IDEASI ===")
for x in ideasi: print(x)
print("\n=== DEFINISI ===")
for x in definisi: print(x)
