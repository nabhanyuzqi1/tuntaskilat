# Roadmap Produksi Tuntaskilat

> Prinsip (arahan owner): **stabilkan dulu sampai 100% layak produksi, lalu
> tambah fitur pelan-pelan — jangan misfungsi.** Fitur di bawah diurutkan per
> fase; tiap fase harus lulus uji end-to-end sebelum fase berikutnya dimulai.

## Fase 0 — Stabilisasi (SEDANG BERJALAN)
Semua bug fungsional ditutup (lihat task list sesi debugging). Sisa:
- [ ] Verifikasi P6 Rincian Tagihan di HP fisik (build baru).
- [ ] CORS bucket Storage untuk admin web (foto profil/bukti tampil di web):
  jalankan sekali dari mesin ber-gcloud:
  `gsutil cors set docs/cors.json gs://tuntaskilat-homeservices.firebasestorage.app`
  (cors.json: origin `["*"]` → produksi: domain admin saja, method GET).
- [ ] Deploy Cloud Functions (`firebase deploy --only functions`) — dibutuhkan
  push FCM order (suara notifikasi kru) & kas tunai. Butuh plan Blaze.

## Fase 1 — Notifikasi Order Kru ala Gojek/Grab (prioritas #1 owner)
**Tujuan:** kru menerima tawaran order live yang "nyepam" sampai dikonfirmasi,
jendela konfirmasi maks 30 menit, tawaran tak bisa dibatalkan pelanggan selama
jendela berjalan.

Desain teknis (tanpa merombak arsitektur):
1. **Koleksi baru `offers`**: `{orderId, cleanerId, dibuat, kadaluarsa(+30m),
   status: ditawarkan|diterima|kadaluarsa}` — dibuat Cloud Function saat admin
   menugaskan (atau auto-assign nanti). Rules: kru hanya bisa update
   `status→diterima` miliknya sebelum `kadaluarsa`.
2. **FCM data-message** ke token kru → app kru menampilkan **full-screen
   notification** (`flutter_local_notifications`:
   `fullScreenIntent: true`, `category: AndroidNotificationCategory.call`,
   `ongoing: true`, suara looping channel khusus `tk_offer_channel_v1`
   + `audioAttributesUsage: alarm`) — persis pola aplikasi ojol.
   Izin manifest: `USE_FULL_SCREEN_INTENT`.
3. **Re-notify** tiap 20 dtk selama belum direspons (AlarmManager/`ongoing`),
   berhenti saat diterima/kadaluarsa.
4. **Countdown 30 menit** di K2/K3 (chip merah waktu tersisa). Lewat 30 menit →
   Function `onOfferExpired` melepas penugasan → order kembali ke antrean +
   notifikasi admin.
5. Pelanggan TIDAK bisa membatalkan selama offer berjalan → tombol Batalkan di
   P8 disembunyikan bila `status == ditugaskan && offer aktif` + rules menolak
   `status→dibatalkan` pada fase itu.

## Fase 2 — Geofence Anomali Kru + Daftar Pengawasan Admin
**Tujuan:** deteksi kru menekan "Mulai Pengerjaan"/"Selesai" jauh dari titik
rumah pelanggan; peringatan ke kru, tercatat & dipantau admin; rawan sanksi.

1. Klien kru: saat tombol progres ditekan, ambil posisi GPS → hitung jarak ke
   `order.lokasi` (haversine, util sudah ada di tk_core Validators).
   - > 150 m: dialog peringatan "Anda di luar titik layanan" (boleh lanjut
     dengan alasan, wajib isi).
2. Tulis `anomalies/{id}`: `{orderId, cleanerId, jenis: mulai|selesai,
   jarakMeter, posisi, alasan, waktu}` — create oleh kru (rules), read admin.
3. **Admin A5+**: tab "Pengawasan" — daftar anomali per kru (badge jumlah 30
   hari), tombol beri Surat Peringatan (menambah `kru.peringatan[]`) dan
   eskalasi ke nonaktif (Fase 4).
4. Anti-spoof lanjutan (fase berikutnya): `isMockLocation` dari geolocator,
   dan verifikasi EXIF/timestamp foto laporan.

## Fase 3 — Multi-Role Admin (Superadmin) & Pengaturan Sensitif
**Tujuan:** payment gateway, Fonnte/WA, API pihak ketiga hanya untuk
superadmin; anti "jebol role".

1. `users.role` tetap 3 nilai (kompatibel TA); tambah flag terpisah
   `users.adminLevel: 'super' | 'staff'` (default staff).
2. **Sumber kebenaran di server**: Security Rules —
   `isSuper() { role=='admin' && adminLevel=='super' }`;
   koleksi `settings/{gateway|fonnte|apiKeys}` → `read, write: if isSuper()`.
   Staff hanya `settings/rekening` (operasional). Klien cuma menyembunyikan
   menu; penegakan sesungguhnya di rules (tidak bisa dibobol dari UI).
3. API key pihak ketiga **jangan disimpan di Firestore yang terbaca klien** —
   simpan di Cloud Functions config/Secret Manager; klien memanggil callable
   function (mis. kirim WA via Fonnte) yang memverifikasi `adminLevel` dari
   token custom claims. Set custom claim via function `setAdminLevel`
   (hanya boleh dipanggil superadmin).
4. Audit log `adminLogs/{id}` untuk setiap perubahan pengaturan sensitif.

## Fase 4 — Lifecycle Kru / Mitra / Vendor
**Tujuan:** perusahaan bisa memberi SP, menonaktifkan sementara, atau
**memecat (nonaktif permanen)** kru; siap ekspansi tipe mitra/vendor.

1. `kru.statusKemitraan: aktif | ditangguhkan | diberhentikan` +
   `users.nonaktif` (sudah ada) dipaksa di **login kru** (tolak bila
   nonaktif/diberhentikan → pesan "Akun dinonaktifkan, hubungi kantor") dan di
   rules (`kru` update ketersediaan ditolak bila diberhentikan).
2. A5: aksi SP1/SP2/SP3 (dari daftar pengawasan Fase 2), Tangguhkan (sementara,
   reversible), Berhentikan (permanen — konfirmasi ganda, alasan wajib,
   tercatat di `adminLogs`). Diberhentikan → offer/penugasan aktif dilepas.
3. `tipeMitra: kru_internal | mitra_lepas | vendor` di dokumen kru — pembeda
   skema upah/komisi (vendor: invoice, mitra: bagi hasil, internal: payroll).

## Fase 5 — Jasa Tambahan di Lokasi (anti main-belakang)
**Masalah:** pelanggan minta kerjaan ekstra di luar paket → kru & pelanggan
berdamai di belakang, perusahaan buntung.

**Desain "Add-on On-Site" yang adil untuk 3 pihak:**
1. Di K3 ada tombol **"+ Jasa Tambahan"**: kru memilih item dari katalog add-on
   resmi (harga tetap dari `services/addOns` — bukan angka bebas) → sistem
   membuat `orderAddons/{id}` status `menunggu_persetujuan`.
2. **Pelanggan menyetujui DI APP-nya** (P8 muncul kartu persetujuan + harga) —
   tanpa persetujuan digital, add-on tidak sah dan tidak boleh dikerjakan.
3. Pembayaran add-on masuk sistem (tunai dicatat ke kasKru seperti order tunai;
   non-tunai = tagihan tambahan) → masuk komisi kru resmi. Kru justru UNTUNG
   melapor (dapat komisi + poin) — insentif jujur.
4. Deteksi kecurangan pendukung: durasi di lokasi >> estimasi paket tanpa
   add-on tercatat → tandai ke daftar pengawasan (Fase 2); ulasan pelanggan
   berisi kata kunci jasa di luar paket → flag.
5. Kebijakan tertulis di onboarding kru: transaksi di luar app = pelanggaran
   berat (SP3/pemberhentian) — didukung jejak digital di atas.

## Fase 6 — Multi-Cabang / Wilayah
1. Koleksi `branches/{branchId}`: nama, kota, geo-polygon/radius layanan,
   rekening, admin staff terkait.
2. Tambah `branchId` pada `users(kru)`, `orders`, `services` (harga per
   cabang opsional). Order otomatis memilih cabang dari titik peta (point-in-
   radius); validasi "Out of Delivery Range" per cabang menggantikan konstanta
   Sampit di `Validators.isDalamWilayahSampit`.
3. Admin: pemilih cabang global (superadmin lihat semua; staff terkunci ke
   cabangnya via custom claim `branchId`).
4. Catatan TA: ini pengembangan produk nyata pasca-sidang (Bab V "saran
   pengembangan") — tidak mengubah klaim naskah.

## Backlog kecil
- CORS + thumbnail (resize via extension) untuk foto di admin web.
- `flutter_launcher_icons`/native_splash regenerate saat brand berubah.
- Rate-limit login admin (App Check + reCAPTCHA).
