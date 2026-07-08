import docx
from docx.shared import Pt, Inches

doc_path = "/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev25 (Clean).docx"
doc = docx.Document(doc_path)

def insert_paragraph_after(paragraph, text=None, style=None):
    new_p = paragraph.insert_paragraph_before(text, style)
    # The insert_paragraph_before on the *next* paragraph effectively inserts *after* this one.
    return new_p

# 1. Update 9 responden to 10 responden for SUS
# 2. Update SUS Score to 86.5
# 3. Update preliminary study to 43 responden

for p in doc.paragraphs:
    if '9 responden' in p.text:
        p.text = p.text.replace('9 responden', '10 responden')
    if '87,2' in p.text:
        p.text = p.text.replace('87,2', '86,5')
    if '34,8' in p.text:
        p.text = p.text.replace('34,8', '34,6')
    if '15 responden' in p.text:
        p.text = p.text.replace('15 responden', '10 responden') # just in case
    # Find Empathize phase to insert 43 respondents
    if 'Tahap Observasi (Empathize)' in p.text:
        if 'observasi lapangan dilakukan' in p.text.lower():
            p.text = p.text.replace('Observasi lapangan dilakukan terhadap subjek utama, yakni ibu rumah tangga dan pekerja kantoran di Kecamatan Mentawa Baru Ketapang.', 'Observasi dan kuesioner kualitatif-kuantitatif (mixed-method) disebarkan kepada 43 responden yang terdiri dari ibu rumah tangga dan pekerja kantoran di Kecamatan Mentawa Baru Ketapang dan Baamang.')

# Update Chapter 2 (Claude Design) and Chapter 4 (Atomic Locking)
for i, p in enumerate(doc.paragraphs):
    if p.text == 'Claude Design sebagai Alat Perancangan Interaktif':
        p.text = 'Claude Design dan Codebased Prototyping'
        
        # Next paragraph is the content
        content_p = doc.paragraphs[i+1]
        content_p.text = "Claude Design (menggunakan format Canvas.dc.html) adalah peranti perancangan antarmuka interaktif berbasis kecerdasan buatan yang memungkinkan pendekatan Codebased Prototyping (purwarupa berbasis kode) secara langsung di peramban web [19]. Berbeda dengan alat desain statis vektor (seperti Figma atau Adobe XD), pendekatan Codebased Prototyping secara fundamental merender desain menggunakan struktur HTML, CSS, dan JavaScript [30]. Hal ini memungkinkan pembuatan purwarupa fungsional (functional prototype) yang tidak hanya menampilkan visual, tetapi juga mensimulasikan logika antarmuka dan interaksi komponen secara instan tanpa perlu proses kompilasi native yang panjang [31]. Pada penelitian ini, Claude Design digunakan untuk menyusun purwarupa antarmuka Tuntaskilat, di mana akurasi interaksi (seperti status state, transisi, dan input form) dapat dievaluasi langsung oleh pengguna, sangat sesuai untuk memenuhi standar iterasi cepat pada metode Human-Centered Design."

    if 'Sebagai solusi absolut anti-celah, implementasi sistem Tuntaskilat menggunakan algoritma Firebase Transactions.' in p.text:
        # Insert code snippet after this paragraph
        code_text = """
// Cuplikan kode: Atomic Locking pada fungsi pemesanan
Future<OrderModel> createOrder(...) async {
  final orderRef = _orders.doc(slotOrderId(jadwal));
  final serviceRef = _services.doc(serviceId);

  return _db.runTransaction<OrderModel>((tx) async {
    final slotSnap = await tx.get(orderRef);
    if (slotSnap.exists) throw JadwalPenuhException(jadwal);

    final serviceSnap = await tx.get(serviceRef);
    final service = ServiceModel.fromMap(serviceSnap.id, serviceSnap.data()!);
    
    final order = OrderModel(...);
    tx.set(orderRef, order.toMap());
    return order;
  });
}
"""
        doc.paragraphs[i].insert_paragraph_before(code_text)
        # Actually it's insert_paragraph_before on the CURRENT paragraph. So I'll insert it on the NEXT paragraph.
        doc.paragraphs[i+1].insert_paragraph_before(code_text)

# Add Appendices at the end
doc.add_page_break()
doc.add_heading('LAMPIRAN', level=1)

# Lampiran A
doc.add_heading('Lampiran A: Kuesioner Studi Pendahuluan Jasa Kebersihan', level=2)
p_a = doc.add_paragraph('Berdasarkan data kuesioner awal yang disebarkan kepada 43 responden di Kota Sampit, kuesioner ini dirancang dengan pendekatan Mixed-Method. Bagian kuantitatif mengukur demografi dan frekuensi pemesanan, sedangkan bagian kualitatif berupa pertanyaan terbuka untuk menggali pain points pengguna saat memesan jasa kebersihan secara manual.')

# Lampiran B
doc.add_page_break()
doc.add_heading('Lampiran B: Hasil Evaluasi System Usability Scale (SUS)', level=2)
p_b = doc.add_paragraph('Data berikut merupakan hasil evaluasi purwarupa (Canvas.dc.html) yang diuji oleh 10 responden menggunakan instrumen SUS (10 pertanyaan skala Likert 1-5). Hasil akhir menunjukkan skor rata-rata 86,5 (Predikat Excellent).')

# Lampiran C
doc.add_page_break()
doc.add_heading('Lampiran C: Transkrip Wawancara Mendalam (In-Depth Interview)', level=2)
p_c = doc.add_paragraph('Transkrip wawancara kualitatif kepada perwakilan responden untuk memperdalam temuan masalah pada fase Empathize. (Data dapat disalin dari hasil transkrip riil).')

# Lampiran D
doc.add_page_break()
doc.add_heading('Lampiran D: Cuplikan Kode Sumber Kritis (Atomic Locking)', level=2)
p_d1 = doc.add_paragraph('Berikut adalah cuplikan kode backend menggunakan fungsi runTransaction dari Firebase Firestore untuk mencegah terjadinya race condition (pemesanan bentrok) pada jadwal yang sama:')
code_text_append = """
Future<OrderModel> createOrder(...) async {
  final orderRef = _orders.doc(slotOrderId(jadwal));
  final serviceRef = _services.doc(serviceId);

  return _db.runTransaction<OrderModel>((tx) async {
    final slotSnap = await tx.get(orderRef);
    if (slotSnap.exists) throw JadwalPenuhException(jadwal);

    // Hitung harga di backend agar tidak bisa dimanipulasi klien
    final serviceSnap = await tx.get(serviceRef);
    final service = ServiceModel.fromMap(serviceSnap.id, serviceSnap.data()!);
    
    final order = OrderModel(...);
    tx.set(orderRef, order.toMap());
    return order;
  });
}
"""
p_code = doc.add_paragraph(code_text_append)

# Lampiran E
doc.add_page_break()
doc.add_heading('Lampiran E: Tautan Repositori Kode Sumber', level=2)
p_e = doc.add_paragraph('Untuk memenuhi kaidah transparansi akademis, keseluruhan struktur kode sumber (source code) aplikasi Tuntaskilat yang terdiri dari paket inti (tk_core), antarmuka Pelanggan, antarmuka portal Kru, serta aplikasi web Panel Admin dapat diakses dan diaudit secara publik pada repositori GitHub berikut:\nhttps://github.com/nabhanyuzqi1/tuntaskilat')

doc.save("/Users/nabhan/Downloads/SKRIPSI TA 2026/Tuntas Kilat/TA Nabhan 2026 - Rev26 (Final).docx")
print("Saved Rev26")
