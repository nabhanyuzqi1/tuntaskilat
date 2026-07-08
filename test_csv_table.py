import docx
import csv
import os

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev26 (Final).docx"
doc = docx.Document(doc_path)

# Let's see if we can find the appendices
for i, p in enumerate(doc.paragraphs):
    if 'Lampiran B: Hasil Evaluasi System Usability Scale (SUS)' in p.text:
        print(f"Found Lampiran B at {i}")
