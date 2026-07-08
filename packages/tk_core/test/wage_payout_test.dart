import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji KEADILAN & TANPA CELAH pembagian upah + alur konfirmasi multi-kru.
void main() {
  Penugasan w(String id) =>
      Penugasan(cleanerId: id, nama: id, peran: PeranKru.worker);
  Penugasan h(String id) =>
      Penugasan(cleanerId: id, nama: id, peran: PeranKru.helper);

  group('bagiUpah — invarian komisi + Σ == total (tanpa Rupiah bocor)', () {
    test('2 petugas worker+helper, komisi 20%', () {
      final r = bagiUpah(180000, [w('A'), h('B')]);
      expect(r.komisi, 36000);
      expect(r.pool, 144000);
      expect(r.bagian['A'], 90000); // 144000 * 1.0/1.6
      expect(r.bagian['B'], 54000); // 144000 * 0.6/1.6
      expect(r.totalTerbagi, 180000);
    });

    test('angka ganjil: sisa pembulatan ke lead, Σ tetap persis', () {
      // total yang memicu pembulatan di komisi & split
      final r = bagiUpah(99999, [w('A'), h('B'), h('C')]);
      // Tak ada Rupiah hilang/tercipta:
      expect(r.komisi + r.bagian.values.reduce((a, b) => a + b), 99999);
      // Semua bagian bilangan bulat non-negatif:
      for (final v in r.bagian.values) {
        expect(v, greaterThanOrEqualTo(0));
      }
      // Σ bagian == pool persis:
      expect(r.bagian.values.reduce((a, b) => a + b), r.pool);
    });

    test('1 petugas: seluruh pool ke worker', () {
      final r = bagiUpah(90000, [w('A')]);
      expect(r.komisi, 18000);
      expect(r.bagian['A'], 72000);
      expect(r.totalTerbagi, 90000);
    });

    test('komisi khusus (0%): pool == total', () {
      final r = bagiUpah(100000, [w('A'), w('B')],
          konfig: const KonfigUpah(komisiPersen: 0));
      expect(r.komisi, 0);
      expect(r.bagian['A'], 50000);
      expect(r.bagian['B'], 50000);
    });
  });

  group('konfirmasiSelesaiKru — payout terbit hanya saat SEMUA konfirmasi', () {
    const lokasi = GeoPoint(-2.5329, 112.9508);
    const pelanggan = UserModel(
      userId: 'u1',
      nama: 'Budi',
      email: 'b@e.com',
      noTelepon: '0812',
      alamat: 'Jl. A',
      role: UserRole.pelanggan,
    );
    late FakeFirebaseFirestore db;
    late FirestoreService service;
    late String orderId;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FirestoreService(firestore: db);
      await db.collection('services').doc('cleaning').set(const ServiceModel(
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
                id: 'detail',
                nama: 'Detail Bersih',
                jumlahPetugas: 2,
                hargaTambahJam: 70000,
                durasi: [DurasiOpsi(jam: 2, harga: 180000)],
              ),
            ],
          ).toMap());
      final order = await service.buatPesananLengkap(
        pelanggan: pelanggan,
        serviceId: 'cleaning',
        jadwal: DateTime(2026, 7, 12, 13, 0),
        pilihan: const PilihanHarga(paketId: 'detail', durasiJam: 2),
        alamatLayanan: 'Jl. A',
        lokasi: lokasi,
        metode: MetodeBayar.tunai,
      );
      orderId = order.orderId;
      await service.tugaskanKruMulti(
        order: order,
        penugasan: [w('kruA'), h('kruB')],
        minPetugas: 2,
      );
    });

    test('konfirmasi pertama: belum selesai, belum ada payout', () async {
      final selesai = await service
          .konfirmasiSelesaiKru(orderId: orderId, cleanerId: 'kruA');
      expect(selesai, false);
      final o = await db.collection('orders').doc(orderId).get();
      expect(o.data()!['status'], isNot('selesai'));
      final pay = await db.collection('payouts').get();
      expect(pay.docs, isEmpty);
    });

    test('konfirmasi kedua: selesai + 2 payout adil (Σ == pool)', () async {
      await service.konfirmasiSelesaiKru(orderId: orderId, cleanerId: 'kruA');
      final selesai = await service
          .konfirmasiSelesaiKru(orderId: orderId, cleanerId: 'kruB');
      expect(selesai, true);

      final o = await db.collection('orders').doc(orderId).get();
      expect(o.data()!['status'], 'selesai');

      final pay = await db.collection('payouts').get();
      expect(pay.docs.length, 2);
      final byKru = {
        for (final d in pay.docs) d.data()['cleanerId']: d.data()['jumlah']
      };
      // total 180000, komisi 20% = 36000, pool 144000 → 90000 / 54000
      expect(byKru['kruA'], 90000);
      expect(byKru['kruB'], 54000);
      expect((byKru['kruA'] as num) + (byKru['kruB'] as num), 144000);
    });

    test('kru di luar penugasan tak boleh konfirmasi', () async {
      await expectLater(
        service.konfirmasiSelesaiKru(orderId: orderId, cleanerId: 'asing'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
