import docx

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev18.docx"
doc = docx.Document(doc_path)

for p in doc.paragraphs:
    if p.style.name.startswith('Heading'):
        print(f"{p.style.name}: {p.text}")
