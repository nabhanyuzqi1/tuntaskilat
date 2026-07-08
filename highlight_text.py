import docx
from docx.enum.text import WD_COLOR_INDEX

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev26 (Final).docx"
doc = docx.Document(doc_path)

for p in doc.paragraphs:
    for run in p.runs:
        if '43 responden' in run.text.lower() or '43' in run.text.lower():
            run.font.highlight_color = WD_COLOR_INDEX.YELLOW
        if '10 responden' in run.text.lower() or '86,5' in run.text.lower():
            run.font.highlight_color = WD_COLOR_INDEX.YELLOW
        if '[19]' in run.text or '[30]' in run.text or '[31]' in run.text:
            run.font.highlight_color = WD_COLOR_INDEX.BRIGHT_GREEN
            
doc.save("/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev26 (Final).docx")
print("Highlighted specific terms.")
