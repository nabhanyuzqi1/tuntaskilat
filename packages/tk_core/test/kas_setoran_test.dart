import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

/// Uji buku kas setoran tunai: invarian saldo, terima setoran atomik, dan
/// guard nunggak saat penugasan order tunai. Uang tak boleh bocor/minus.
void main() {
  group('KasKru model', () {
    test('bolehTerimaTunai: true bila saldo ≤ batas', () {
      const a = KasKru(cleanerId: 'a', saldoTunai: 150000);
      const b = KasKru(cleanerId: 'b', saldoTunai: 250000);
      expect(a.bolehTerimaTunai, isTrue);
      expect(b.bolehTerimaTunai, isFalse); // > 200000 default
    });

    test('invarianValid: saldo == masuk − setor', () {
      const k = KasKru(
          cleanerId: 'a', saldoTunai: 40000, totalMasuk: 100000, totalSetor: 60000);
      expect(k.invarianValid, isTrue);
    });
  });

  group('terimaSetoran', () {
    late FakeFirebaseFirestore db;
    late FirestoreService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FirestoreService(firestore: db);
      await db.collection('kasKru').doc('kruA').set(const KasKru(
            cleanerId: 'kruA',
            namaKru: 'Kru A',
            saldoTunai: 100000,
            totalMasuk: 100000,
          ).toMap());
    });

    test('kurangi saldo, catat riwayat, jaga invarian', () async {
      await service.terimaSetoran(
        cleanerId: 'kruA',
        namaKru: 'Kru A',
        jumlah: 60000,
        adminUid: 'admin1',
      );
      final kasSnap = await db.collection('kasKru').doc('kruA').get();
      final kas = KasKru.fromMap('kruA', kasSnap.data()!);
      expect(kas.saldoTunai, 40000);
      expect(kas.totalSetor, 60000);
      expect(kas.invarianValid, isTrue); // 40000 == 100000 − 60000

      final setoran = await db.collection('setoran').get();
      expect(setoran.docs.length, 1);
      expect(setoran.docs.first.data()['jumlah'], 60000);
      expect(setoran.docs.first.data()['diterimaOleh'], 'admin1');
    });

    test('tolak setoran melebihi saldo (tanpa minus)', () async {
      await expectLater(
        service.terimaSetoran(
          cleanerId: 'kruA',
          namaKru: 'Kru A',
          jumlah: 200000,
          adminUid: 'admin1',
        ),
        throwsA(isA<StateError>()),
      );
      // Saldo tak berubah.
      final kasSnap = await db.collection('kasKru').doc('kruA').get();
      expect(kasSnap.data()!['saldoTunai'], 100000);
      final setoran = await db.collection('setoran').get();
      expect(setoran.docs, isEmpty);
    });

    test('tolak jumlah ≤ 0', () async {
      await expectLater(
        service.terimaSetoran(
            cleanerId: 'kruA', namaKru: 'Kru A', jumlah: 0, adminUid: 'a'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('guard nunggak saat penugasan order tunai', () {
    late FakeFirebaseFirestore db;
    late FirestoreService service;

    OrderModel orderTunai() => OrderModel(
          orderId: 'o1',
          userId: 'u1',
          serviceId: 'cleaning',
          cleanerId: '',
          tanggalPesan: DateTime(2026, 7, 10),
          jadwal: DateTime(2026, 7, 12, 10),
          totalHarga: 180000,
          status: OrderStatus.menungguPenugasan,
          hargaSatuan: 90000,
          kuantitas: 1,
          namaLayanan: 'Cleaning',
          satuan: 'paket',
          namaPelanggan: 'Budi',
          teleponPelanggan: '0812',
          alamatLayanan: 'Jl. A',
          catatan: '',
          metodePembayaran: MetodeBayar.tunai,
        );

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FirestoreService(firestore: db);
      await db.collection('orders').doc('o1').set(orderTunai().toMap());
    });

    test('lead nunggak > batas → KruNunggakException, order tak ditugaskan',
        () async {
      await db.collection('kasKru').doc('kruA').set(const KasKru(
            cleanerId: 'kruA',
            namaKru: 'Kru A',
            saldoTunai: 250000, // di atas batas 200000
            totalMasuk: 250000,
          ).toMap());

      await expectLater(
        service.tugaskanKruMulti(
          order: orderTunai(),
          penugasan: const [
            Penugasan(cleanerId: 'kruA', nama: 'Kru A', peran: PeranKru.worker),
          ],
        ),
        throwsA(isA<KruNunggakException>()),
      );
      final o = await db.collection('orders').doc('o1').get();
      expect(o.data()!['status'], OrderStatus.menungguPenugasan.wire);
    });

    test('lead tanpa tunggakan → penugasan sukses', () async {
      await service.tugaskanKruMulti(
        order: orderTunai(),
        penugasan: const [
          Penugasan(cleanerId: 'kruB', nama: 'Kru B', peran: PeranKru.worker),
        ],
      );
      final o = await db.collection('orders').doc('o1').get();
      expect(o.data()!['status'], OrderStatus.ditugaskan.wire);
      expect((o.data()!['kruIds'] as List), contains('kruB'));
    });
  });
}
