import docx

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev26 (Final).docx"
doc = docx.Document(doc_path)

for i, p in enumerate(doc.paragraphs):
    if 'nielsen' in p.text.lower() or 'empathize' in p.text.lower():
        print(f"[{i}] {p.text[:100]}...")
