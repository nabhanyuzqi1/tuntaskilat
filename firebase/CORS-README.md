# CORS bucket Firebase Storage (foto di Admin Web)

Admin Web (Flutter web) memuat foto kru/bukti bayar/QRIS lewat `<img>`/CanvasKit.
Browser memblokir gambar lintas-origin dari bucket Storage kecuali bucket
mengizinkan origin admin lewat header CORS. Tanpa ini, foto tampil kosong di
web (di aplikasi Android tidak terpengaruh).

Kode sudah aman tanpa CORS: avatar kru jatuh ke inisial saat gambar gagal
(A5), jadi UI tidak rusak. Terapkan CORS hanya bila ingin foto benar-benar
muncul di panel admin.

## Cara menerapkan (butuh gcloud/gsutil + login)

```bash
# 1. Pasang Google Cloud SDK (sekali saja): https://cloud.google.com/sdk
# 2. Login akun yang punya akses project:
gcloud auth login
# 3. Terapkan CORS ke bucket:
gsutil cors set firebase/cors.json gs://tuntaskilat-homeservices.firebasestorage.app
# 4. Verifikasi:
gsutil cors get gs://tuntaskilat-homeservices.firebasestorage.app
```

Nama bucket bisa dicek di `apps/*/lib/firebase_options.dart` (`storageBucket`).
Jika deploy admin ke domain lain, tambahkan origin domain itu ke `cors.json`
lalu jalankan ulang `gsutil cors set`.
