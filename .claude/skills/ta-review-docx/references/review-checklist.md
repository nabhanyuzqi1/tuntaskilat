# Checklist Audit TA Tuntaskilat

Urut dari paling material (bisa menjegal saat sidang) → administratif. Tandai
tiap butir: ✅ oke / ⚠️ perlu perbaikan / ❌ hilang / — tak berlaku.

## A. Kesetiaan kode ↔ naskah (paling material)
Untuk tiap klaim, cari bukti di repo `tuntaskilat`. Laporkan lokasi buktinya.

- [ ] **Atomic Locking (Bab IV 4.2.2)** benar-benar `runTransaction` + kunci slot
      deterministik → `packages/tk_core/lib/services/firestore_service.dart`
      (`slotOrderId`, `buatPesananLengkap`) + unit test race condition.
- [ ] **Tujuh koleksi** (bukan "tiga"): `users, services, orders, kru, payments,
      reviews, notifications` — cocok `tk_core/lib/models/` & Kamus Data Tabel 3.8.
- [ ] **Tiga aplikasi terpisah** tercermin di `apps/` dan dijelaskan naskah
      sebagai penyempurnaan pasca-perancangan (bukan diklaim "3 APK" di naskah asli).
- [ ] **Fixed pricing divalidasi backend**: harga dihitung ulang di transaction,
      tak menerima angka klien.
- [ ] **Security Rules owner-only** + field uang/kepemilikan immutable klien.
- [ ] **Real-time**: `snapshots()`/StreamBuilder untuk status pesanan & `kru.posisi`.
- [ ] **Graceful degradation** (marker bertahan saat koneksi putus).
- [ ] Tidak ada **overclaim**: mis. "KTP digital mitra" padahal hanya badge
      terverifikasi + rating; "Verified Identity" dsb.

## B. Kepatuhan scope (Batasan Masalah, Bab I)
- [ ] Android untuk Pelanggan/Kru; Web untuk Admin; tidak ada iOS/Web pelanggan.
- [ ] 100% Firebase; tanpa server terpisah; tanpa payment gateway otomatis;
      tanpa harga dinamis; wilayah Sampit.
- [ ] Deviasi sadar-skema punya alasan / tercatat sebagai Saran Bab V (biaya
      "Gratis" & diskon tak dirender; foto profil P15; catatan/checklist kru K4;
      nomor CS placeholder; A6 Biaya&Komisi + Tim Admin ditunda).

## C. Validitas pengujian
- [ ] **8 skenario Black-Box (Tabel 4.1)** semuanya "Valid" di naskah — konfirmasi
      benar-benar dibuktikan unit test/emulator (tk_core: race condition, harga
      backend, kru offline, validator, slot terisi, dll.).
- [ ] **SUS 87,0 = SIMULASI** (bukan 50 responden riil) — WAJIB ditandai jujur;
      rencana uji ulang ke pengguna Sampit nyata.
- [ ] Aritmetika SUS: Σ skor konversi 10 item = 34,8 → ×2,5 = 87,0 (hitung ulang).

## D. Integritas gambar
- [ ] Setiap caption "Gambar X.Y" punya objek gambar (bukan cuma caption+narasi).
      Cek programatik (verify_docx.py), jangan percaya teks.
- [ ] Penomoran gambar per bab berurutan (tak ada 2.4→2.1→2.2, tak ada duplikat
      "3.18" ganda).
- [ ] Nomor internal diagram (UML/flowchart) cocok dengan nomor caption.
- [ ] **Gambar 3.11 State Diagram** benar-benar tertempel (pernah hilang di Rev17).

## E. Sitasi & Daftar Pustaka
- [ ] Tak ada referensi yatim (di pustaka tapi tak disitasi) — sertakan isi
      TABEL ke `body` saat mengecek (sitasi sering di sel tabel).
- [ ] Tak ada sitasi tanpa entri.
- [ ] Sampling verifikasi DOI/judul via WebSearch/doi.org (cek fabrikasi).

## F. Konsistensi administratif
- [ ] Nama mahasiswa & dosen konsisten (typo mirip: "Mubarok" vs "Muibarok").
- [ ] NIDN/NPM sama persis (termasuk titik pemisah). Gelar seragam (mis.
      "Lukman Bachtiar, S.Kom., M.M., M.Kom." di semua tempat).
- [ ] Placeholder terisi: tanggal sidang (14 Juli 2026), JUDUL Lembar Persetujuan.
- [ ] Urutan tanggal masuk akal (tanda tangan tidak sebelum tanggal seminar).

## G. Bahasa (EYD/PUEBI)
- [ ] Istilah asing belum-serap dicetak miring — cari yang tak-konsisten
      (italic di satu tempat, polos di tempat lain) sebagai bukti pelanggaran.
      Kecualikan nama produk (Cloud Firestore, Firebase, Google Play).
- [ ] Istilah teknis yang dipakai (apalagi jadi judul sub-bab: "Implementasi
      Backend/Frontend") sudah didefinisikan di Landasan Teori.

## H. Kepatuhan revisi dosen (jika ada form PDF)
- [ ] Render form ke PNG (`pdftoppm -png -r 150`) + baca visual: tangkap
      centang/silang/coretan tangan, bukan hanya teks cetak + paraf ACC.
- [ ] Tiap item revisi → status: sudah ditindaklanjuti / tidak ditemukan /
      ambigu, dengan kutipan lokasi bukti di naskah.
- [ ] Kontradiksi (anotasi "belum" meski ada paraf ACC) dilaporkan tersendiri.
