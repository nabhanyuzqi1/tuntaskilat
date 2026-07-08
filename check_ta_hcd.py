import docx

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/TA Nabhan 2026 - Rev18.docx"
doc = docx.Document(doc_path)

wireframe_mentions = []
hcd_steps = []

for i, p in enumerate(doc.paragraphs):
    text = p.text.lower()
    if 'wireframe' in text:
        wireframe_mentions.append((i, p.text))
    if 'definisi' in text or 'perumusan masalah' in text:
        hcd_steps.append((i, p.text))
    if 'ideasi' in text or 'alur layanan' in text:
        hcd_steps.append((i, p.text))

print("--- WIREFRAME MENTIONS ---")
for i, t in wireframe_mentions:
    print(f"Para {i}: {t}")

print("\n--- HCD STEPS MENTIONS (IDEASI/DEFINISI) ---")
for i, t in hcd_steps[:15]: # Limit to first 15 to avoid clutter
    print(f"Para {i}: {t}")
