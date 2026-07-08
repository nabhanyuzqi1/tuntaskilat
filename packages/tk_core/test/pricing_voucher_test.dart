import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji lapisan produk nyata: harga dinamis (pricelist TK) + voucher.
/// Semua angka dihitung ULANG di backend (transaction) — angka klien diabaikan.
void main() {
  const lokasiSampit = GeoPoint(-2.5329, 112.9508);
  const pelanggan = UserModel(
    userId: 'u1',
    nama: 'Budi',
    email: 'b@e.com',
    noTelepon: '0812',
    alamat: 'Jl. A, Sampit',
    role: UserRole.pelanggan,
  );

  // ---- Layanan contoh sesuai pricelist ----
  const rumput = ServiceModel(
    serviceId: 'rumput',
    namaLayanan: 'Jasa Rumput',
    deskripsi: '',
    harga: 1200,
    satuan: 'm²',
    aktif: true,
    ikon: 'grass',
    tipeHarga: TipeHarga.perLuas,
    tiers: [
      TarifTier(id: 'ringan', nama: 'Rumput ringan', hargaPerM2: 1200),
      TarifTier(id: 'ilalang', nama: 'Ilalang tinggi', hargaPerM2: 2800),
    ],
  );
  const cleaning = ServiceModel(
    serviceId: 'cleaning',
    namaLayanan: 'Home Cleaning',
    deskripsi: '',
    harga: 90000,
    satuan: 'paket',
    aktif: true,
    ikon: 'cleaning_services',
    tipeHarga: TipeHarga.paket,
    paketOpsi: [
      PaketOpsi(
        id: 'reguler',
        nama: 'Reguler',
        jumlahPetugas: 1,
        hargaTambahJam: 35000,
        durasi: [DurasiOpsi(jam: 2, harga: 90000), DurasiOpsi(jam: 3, harga: 130000)],
      ),
    ],
    addOns: [
      AddOn(id: 'sofa', nama: 'Vacum sofa', harga: 30000),
      AddOn(id: 'kulkas', nama: 'Bagian dalam kulkas', harga: 25000),
    ],
  );

  group('Kalkulasi harga dinamis', () {
    test('perLuas: tier × luas', () {
      final h = rumput.hitungHarga(
          const PilihanHarga(tierId: 'ilalang', luas: 50));
      expect(h.subtotal, 2800 * 50);
    });

    test('paket: durasi + tambah jam + add-on', () {
      final h = cleaning.hitungHarga(const PilihanHarga(
        paketId: 'reguler',
        durasiJam: 3,
        tambahJam: 2,
        addOnIds: ['sofa', 'kulkas'],
      ));
      // 130000 + (2×35000) + 30000 + 25000
      expect(h.subtotal, 130000 + 70000 + 30000 + 25000);
      expect(h.rincian.length, 4);
    });

    test('mulaiDari: harga × kuantitas', () {
      const semprot = ServiceModel(
        serviceId: 'semprot',
        namaLayanan: 'Semprot gulma',
        deskripsi: '',
        harga: 25000,
        satuan: 'titik',
        aktif: true,
        ikon: 'sanitizer',
      );
      final h = semprot.hitungHarga(const PilihanHarga(kuantitas: 3));
      expect(h.subtotal, 75000);
    });
  });

  group('Voucher — perhitungan potongan', () {
    final now = DateTime(2026, 7, 8);
    test('persen dengan batas maksimum', () {
      const v = VoucherModel(
        voucherId: 'HEMAT20',
        kode: 'HEMAT20',
        tipe: TipeVoucher.persen,
        nilai: 20,
        maxPotongan: 25000,
      );
      final r = v.hitungPotongan(200000, now); // 20% = 40000, dibatasi 25000
      expect(r.potongan, 25000);
      expect(r.tolak, isNull);
    });

    test('nominal tetap', () {
      const v = VoucherModel(
        voucherId: 'POTONG10K',
        kode: 'POTONG10K',
        tipe: TipeVoucher.nominal,
        nilai: 10000,
      );
      expect(v.hitungPotongan(90000, now).potongan, 10000);
    });

    test('tolak: minimal belanja belum tercapai', () {
      const v = VoucherModel(
        voucherId: 'MIN100',
        kode: 'MIN100',
        tipe: TipeVoucher.nominal,
        nilai: 15000,
        minBelanja: 100000,
      );
      expect(v.hitungPotongan(90000, now).tolak, VoucherTolak.minimalBelanja);
    });

    test('tolak: kadaluarsa', () {
      final v = VoucherModel(
        voucherId: 'EXP',
        kode: 'EXP',
        tipe: TipeVoucher.nominal,
        nilai: 5000,
        berlakuHingga: DateTime(2026, 7, 1),
      );
      expect(v.hitungPotongan(90000, now).tolak, VoucherTolak.kadaluarsa);
    });
  });

  group('buatPesananLengkap — voucher divalidasi & kuota berkurang', () {
    late FakeFirebaseFirestore db;
    late FirestoreService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FirestoreService(firestore: db);
      await db.collection('services').doc('cleaning').set(cleaning.toMap());
      await db.collection('vouchers').doc('HEMAT20').set(const VoucherModel(
            voucherId: 'HEMAT20',
            kode: 'HEMAT20',
            tipe: TipeVoucher.persen,
            nilai: 20,
            kuota: 1,
          ).toMap());
    });

    test('order menerapkan potongan & menaikkan terpakai', () async {
      final order = await service.buatPesananLengkap(
        pelanggan: pelanggan,
        serviceId: 'cleaning',
        jadwal: DateTime(2026, 7, 10, 13, 0),
        pilihan: const PilihanHarga(paketId: 'reguler', durasiJam: 2),
        alamatLayanan: 'Jl. A, Sampit',
        lokasi: lokasiSampit,
        metode: MetodeBayar.tunai,
        voucherKode: 'hemat20', // huruf kecil pun diterima
      );
      expect(order.subtotal, 90000);
      expect(order.potongan, 18000); // 20% dari 90000
      expect(order.totalHarga, 72000);
      expect(order.voucherKode, 'HEMAT20');

      final v = await db.collection('vouchers').doc('HEMAT20').get();
      expect(v.data()!['terpakai'], 1);
    });

    test('kuota habis → VoucherException, order tidak dibuat', () async {
      // Habiskan kuota (1) lewat pemesanan pertama.
      await service.buatPesananLengkap(
        pelanggan: pelanggan,
        serviceId: 'cleaning',
        jadwal: DateTime(2026, 7, 10, 13, 0),
        pilihan: const PilihanHarga(paketId: 'reguler', durasiJam: 2),
        alamatLayanan: 'Jl. A, Sampit',
        lokasi: lokasiSampit,
        metode: MetodeBayar.tunai,
        voucherKode: 'HEMAT20',
      );
      await expectLater(
        service.buatPesananLengkap(
          pelanggan: pelanggan,
          serviceId: 'cleaning',
          jadwal: DateTime(2026, 7, 11, 13, 0),
          pilihan: const PilihanHarga(paketId: 'reguler', durasiJam: 2),
          alamatLayanan: 'Jl. B, Sampit',
          lokasi: lokasiSampit,
          metode: MetodeBayar.tunai,
          voucherKode: 'HEMAT20',
        ),
        throwsA(isA<VoucherException>()),
      );
    });
  });
}
