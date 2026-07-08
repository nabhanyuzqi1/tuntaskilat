import docx
doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev24.docx"
doc = docx.Document(doc_path)
in_bab5 = False
for p in doc.paragraphs:
    if p.text.strip().upper() == "BAB V" or p.text.strip().upper() == "BAB 5":
        in_bab5 = True
    if in_bab5:
        print(p.text)
