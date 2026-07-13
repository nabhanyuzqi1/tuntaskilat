# Tes unit Security Rules Firestore

Menguji `firebase/firestore.rules` terhadap emulator Firestore dengan
`@firebase/rules-unit-testing` — memastikan aturan uang/kepemilikan,
pembatasan pembacaan order, kunci slot, banner, dan broadcast tidak
melonggar tanpa sengaja.

## Menjalankan

Butuh **Node 18+**, **Firebase CLI**, dan **Java (JDK 11+)** untuk emulator.

```bash
cd firebase/test
npm install
npm test        # = firebase emulators:exec --only firestore "vitest run"
```

`npm test` menyalakan emulator Firestore sementara, menjalankan seluruh
suite `vitest`, lalu mematikan emulator.

## Cakupan (`firestore.rules.test.js`)

| Grup | Yang diverifikasi |
|------|-------------------|
| services | katalog publik dibaca tamu; tulis hanya admin |
| orders create | `hargaSatuan == services.harga`, `total == subtotal − potongan`, potongan hanya sah bila voucher ada, userId = diri sendiri |
| orders get/list | hanya peserta (pemilik/kru tertugas/admin) — anti-enumerasi PII |
| orders update | batal hanya dari status pra-penugasan; field uang tak bisa diubah klien |
| slots | dibaca pengguna login; dibuat pemilik; hapus hanya admin |
| banners | publik baca (guest mode); tulis hanya admin |
| broadcasts | admin-only |

## Catatan lingkungan

Emulator Firestore (Netty) butuh koneksi loopback lokal; pada sebagian
sandbox CI/agen yang membatasi loopback JVM, emulator gagal start
(`Unable to establish loopback connection`). Jalankan di mesin dev biasa
atau runner CI dengan jaringan loopback penuh.
