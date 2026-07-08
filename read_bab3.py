import docx
doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev18.docx"
doc = docx.Document(doc_path)
in_bab3 = False
bab3_text = []
for p in doc.paragraphs:
    text = p.text.upper()
    if text.startswith('BAB III'):
        in_bab3 = True
    if text.startswith('BAB IV'):
        in_bab3 = False
    if in_bab3:
        bab3_text.append(p.text)
        
for i, line in enumerate(bab3_text):
    if len(line.strip()) > 0:
        print(f"{i}: {line}")
