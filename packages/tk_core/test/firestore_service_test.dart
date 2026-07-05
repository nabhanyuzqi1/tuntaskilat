import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

void main() {
  const pelanggan = UserModel(
    userId: 'u1',
    nama: 'Budi Santoso',
    email: 'budi@email.com',
    noTelepon: '081234567890',
    alamat: 'Jl. Ahmad Yani, Sampit',
    role: UserRole.pelanggan,
  );
  const pelangganLain = UserModel(
    userId: 'u2',
    nama: 'Sari Dewi',
    email: 'sari@email.com',
    noTelepon: '081298765432',
    alamat: 'Jl. Iskandar, Sampit',
    role: UserRole.pelanggan,
  );
  const lokasiSampit = GeoPoint(-2.5329, 112.9508);
  final jadwal = DateTime(2026, 7, 10, 13, 0);

  late FakeFirebaseFirestore db;
  late FirestoreService service;

  setUp(() async {
    db = FakeFirebaseFirestore();
    service = FirestoreService(firestore: db);
    await db.collection('services').doc('s1').set({
      'serviceId': 's1',
      'namaLayanan': 'Bersih Rumah',
      'deskripsi': 'Pembersihan menyeluruh per ruangan.',
      'harga': 25000,
      'satuan': 'per ruangan',
      'aktif': true,
      'ikon': 'cleaning_services',
    });
  });

  group('Skenario Black-Box #1 — Atomic Locking slot jadwal', () {
    test('pemesanan pertama sukses, slot yang sama berikutnya gagal (Jadwal Penuh)', () async {
      final order = await service.createOrder(
        pelanggan: pelanggan,
        serviceId: 's1',
        jadwal: jadwal,
        kuantitas: 3,
        alamatLayanan: 'Jl. Ahmad Yani, Sampit',
        lokasi: lokasiSampit,
      );
      expect(order.orderId, FirestoreService.slotOrderId(jadwal));
      expect(order.status, OrderStatus.dibuat);

      expect(
        () => service.createOrder(
          pelanggan: pelangganLain,
          serviceId: 's1',
          jadwal: jadwal,
          kuantitas: 1,
          alamatLayanan: 'Jl. Iskandar, Sampit',
          lokasi: lokasiSampit,
        ),
        throwsA(isA<JadwalPenuhException>()),
      );
    });

    test('slot berbeda tidak saling mengunci', () async {
      await service.createOrder(
        pelanggan: pelanggan,
        serviceId: 's1',
        jadwal: jadwal,
        kuantitas: 3,
        alamatLayanan: 'Jl. Ahmad Yani, Sampit',
        lokasi: lokasiSampit,
      );
      final lain = await service.createOrder(
        pelanggan: pelangganLain,
        serviceId: 's1',
        jadwal: DateTime(2026, 7, 10, 15, 0),
        kuantitas: 2,
        alamatLayanan: 'Jl. Iskandar, Sampit',
        lokasi: lokasiSampit,
      );
      expect(lain.orderId, isNot(FirestoreService.slotOrderId(jadwal)));
    });
  });

  group('Skenario Black-Box #6 — harga dihitung ulang di backend', () {
    test('totalHarga = services.harga × kuantitas, bukan dari klien', () async {
      final order = await service.createOrder(
        pelanggan: pelanggan,
        serviceId: 's1',
        jadwal: jadwal,
        kuantitas: 3,
        alamatLayanan: 'Jl. Ahmad Yani, Sampit',
        lokasi: lokasiSampit,
      );
      // createOrder tidak menerima harga dari klien sama sekali —
      // nilai diambil dari dokumen services di dalam transaction.
      expect(order.hargaSatuan, 25000);
      expect(order.totalHarga, 75000);

      final tersimpan = await db.collection('orders').doc(order.orderId).get();
      expect(tersimpan.data()!['totalHarga'], 75000);
    });

    test('layanan nonaktif tidak bisa dipesan', () async {
      await db.collection('services').doc('s1').update({'aktif': false});
      expect(
        () => service.createOrder(
          pelanggan: pelanggan,
          serviceId: 's1',
          jadwal: jadwal,
          kuantitas: 1,
          alamatLayanan: 'Jl. Ahmad Yani, Sampit',
          lokasi: lokasiSampit,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Skenario Black-Box #8 — koordinat luar Sampit ditolak', () {
    test('Out of Delivery Range', () {
      expect(
        () => service.createOrder(
          pelanggan: pelanggan,
          serviceId: 's1',
          jadwal: jadwal,
          kuantitas: 1,
          alamatLayanan: 'Jakarta',
          lokasi: const GeoPoint(-6.2, 106.8),
        ),
        throwsA(isA<LuarWilayahLayananException>()),
      );
    });
  });

  group('reviews — wajib update rataRating & jumlahUlasan kru (transaction)', () {
    test('rata-rata dihitung ulang benar', () async {
      await db.collection('kru').doc('k1').set({
        'cleanerId': 'k1',
        'nama': 'Andi Rahman',
        'noTelepon': '081211112222',
        'statusKetersediaan': true,
        'rataRating': 4.0,
        'posisi': null,
        'jumlahUlasan': 3,
      });
      await db.collection('orders').doc('o1').set({'status': 'selesai'});

      await service.createReview(
        orderId: 'o1',
        pelanggan: pelanggan,
        cleanerId: 'k1',
        penilaian: 5,
      );

      final kru = await db.collection('kru').doc('k1').get();
      expect(kru.data()!['jumlahUlasan'], 4);
      expect(kru.data()!['rataRating'], closeTo(4.25, 0.001));

      final order = await db.collection('orders').doc('o1').get();
      expect(order.data()!['status'], 'dinilai');
    });
  });

  group('Skenario Black-Box #7 — kru offline hilang dari daftar tersedia', () {
    test('watchAvailableKru hanya memuat statusKetersediaan == true', () async {
      await db.collection('kru').doc('k1').set({
        'cleanerId': 'k1', 'nama': 'Andi', 'noTelepon': '0812',
        'statusKetersediaan': true, 'rataRating': 4.9,
        'posisi': null, 'jumlahUlasan': 10,
      });
      await db.collection('kru').doc('k2').set({
        'cleanerId': 'k2', 'nama': 'Rudi', 'noTelepon': '0813',
        'statusKetersediaan': false, 'rataRating': 4.5,
        'posisi': null, 'jumlahUlasan': 5,
      });

      final tersedia = await service.watchAvailableKru().first;
      expect(tersedia.map((k) => k.cleanerId), ['k1']);

      await service.setKetersediaanKru('k1', false);
      final setelahOffline = await service.watchAvailableKru().first;
      expect(setelahOffline, isEmpty);
    });
  });
}
