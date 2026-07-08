# Struktur Branch — TA vs Produk Nyata

Dipisah agar fitur produk (voucher, harga dinamis, multi-worker, upah/payout,
banding) **tidak mengganggu batasan Tugas Akhir**. Dosen pembimbing (Gemini)
mensyaratkan versi sidang tetap setia ke naskah TA yang sudah disahkan.

| Branch | Isi | Untuk |
|---|---|---|
| **`release/sidang-ta`** | Persis lingkup TA: **fixed pricing**, **1 kru/order**, **7 koleksi**, tanpa voucher/upah. Sesuai Kamus Data & Bab IV. | Sidang, demo TA, audit naskah |
| **`main`** | Produk nyata: harga dinamis (pricelist TK), voucher, multi-worker (worker+helper), bagi upah adil + `payouts`, banding `disputes`. Lapisan DI LUAR TA. | Operasional/bisnis nyata |

> **Jangan** menggabung (`merge`) `main` → `release/sidang-ta`. Perbaikan yang
> relevan untuk keduanya (bug fix murni, tanpa fitur produk) di-*cherry-pick*
> satu per satu.

## Menjalankan tiap branch pada server sendiri (tanpa bentrok)

Aplikasi Pelanggan & Kru = Android (jalan di perangkat/emulator, tanpa port).
Yang butuh "server" hanya **Panel Admin (Flutter Web)**. Port sudah dibedakan
per branch supaya bisa jalan **bersamaan tanpa tabrakan**:

- `release/sidang-ta` → admin-web di **:5599**
- `main` (produk) → admin-web di **:5601**

Karena satu working tree hanya bisa checkout satu branch, gunakan **git
worktree** untuk menjalankan keduanya sekaligus:

```bash
# Dari repo utama (main):
git worktree add ../tkapps-ta release/sidang-ta   # salinan kerja branch TA

# Build + serve masing-masing (terminal terpisah):
cd apps/admin && flutter build web && cd ../.. \
  && python3 -m http.server 5601 --directory apps/admin/build/web   # produk

cd ../tkapps-ta/apps/admin && flutter build web && cd ../.. \
  && python3 -m http.server 5599 --directory apps/admin/build/web   # TA
```

Keduanya kini jalan di port berbeda; app satu branch tak mengganggu yang lain.

## Isolasi data Firebase (penting)

Kedua branch memakai project `tuntaskilat-homeservices` (`.firebaserc` →
`default`). Fitur produk bersifat **aditif**: koleksi baru (`vouchers`,
`payouts`, `disputes`) dan field baru pada `orders` **diabaikan** oleh kode TA,
jadi keduanya bisa berbagi backend tanpa saling merusak — **KECUALI** satu aksi:

- Tombol **Panel Admin → Voucher → "Isi Katalog Pricelist"** menimpa koleksi
  `services` dengan harga dinamis. **Jangan jalankan di project bersama** bila
  data katalog TA harus tetap utuh untuk sidang.

Untuk eksperimen produk tanpa risiko ke data TA, arahkan branch `main` ke
**Firebase Emulator** atau **project Firebase terpisah**. Data sidang TA (4
layanan Hi-Fi, harga tetap) tetap aman selama seed pricelist tidak dijalankan.

## Deploy

`.firebaserc` kini punya `default: tuntaskilat-homeservices`, jadi:

```bash
firebase deploy --only firestore:rules      # rules (main punya vouchers/payouts/disputes)
firebase deploy --only hosting:admin        # panel admin
```

Rules di `main` lebih luas (koleksi produk). Deploy rules `main` ke project
bersama tidak memutus app TA (rules produk hanya menambah izin koleksi baru).
