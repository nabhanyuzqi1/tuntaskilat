import docx

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev27 (Final).docx"
doc = docx.Document(doc_path)

for i, p in enumerate(doc.paragraphs):
    text = p.text.lower()
    if 'play' in text and 'store' in text or '14 hari' in text:
        print(f"[{i}] {p.text}")
