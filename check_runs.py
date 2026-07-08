import docx
doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev24.docx"
doc = docx.Document(doc_path)
for idx in [678, 698, 754, 761, 770]:
    p = doc.paragraphs[idx]
    print(f"--- Paragraph {idx} ---")
    for r in p.runs:
        print(f"Run text: '{r.text}' | Bold: {r.bold} | Italic: {r.italic}")
