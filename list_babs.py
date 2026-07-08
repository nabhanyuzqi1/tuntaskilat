import docx
doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev18.docx"
doc = docx.Document(doc_path)
for p in doc.paragraphs:
    text = p.text.upper()
    if text.startswith('BAB '):
        print(text)
    elif p.style.name.startswith('Heading 1'):
        print(f"H1: {text}")
