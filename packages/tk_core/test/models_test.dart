import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tk_core/tk_core.dart';

void main() {
  group('Serialisasi model bolak-balik (nama field persis Kamus Data TA)', () {
    test('UserModel', () {
      const user = UserModel(
        userId: 'u1',
        nama: 'Budi Santoso',
        email: 'budi@email.com',
        noTelepon: '081234567890',
        alamat: 'Jl. Ahmad Yani, Sampit',
        role: UserRole.pelanggan,
      );
      final map = user.toMap();
      expect(map.keys, containsAll(['userId', 'nama', 'email', 'noTelepon', 'alamat', 'role']));
      expect(map['role'], 'pelanggan');
      final kembali = UserModel.fromMap('u1', map);
      expect(kembali.nama, user.nama);
      expect(kembali.role, UserRole.pelanggan);
    });

    test('OrderModel — semua field skema, status wire sesuai state diagram', () {
      final order = OrderModel(
        orderId: 'slot_202607101300',
        userId: 'u1',
        serviceId: 's1',
        cleanerId: '',
        tanggalPesan: DateTime(2026, 7, 5, 9, 0),
        jadwal: DateTime(2026, 7, 10, 13, 0),
        totalHarga: 75000,
        status: OrderStatus.menungguPembayaran,
        hargaSatuan: 25000,
        kuantitas: 3,
        namaLayanan: 'Bersih Rumah',
        satuan: 'per ruangan',
        namaPelanggan: 'Budi Santoso',
        teleponPelanggan: '081234567890',
        alamatLayanan: 'Jl. Ahmad Yani, Sampit',
        lokasi: const GeoPoint(-2.5329, 112.9508),
        catatan: 'Fokus dapur',
      );
      final map = order.toMap();
      expect(
        map.keys,
        containsAll([
          'orderId', 'userId', 'serviceId', 'cleanerId', 'tanggalPesan',
          'jadwal', 'totalHarga', 'status', 'hargaSatuan', 'kuantitas',
          'namaLayanan', 'satuan', 'namaPelanggan', 'teleponPelanggan',
          'namaKru', 'alamatLayanan', 'lokasi', 'catatan',
          'fotoSebelum', 'fotoSesudah',
        ]),
      );
      expect(map['status'], 'menunggu_pembayaran');
      final kembali = OrderModel.fromMap(order.orderId, map);
      expect(kembali.jadwal, order.jadwal);
      expect(kembali.totalHarga, 75000);
      expect(kembali.lokasi!.latitude, -2.5329);
    });

    test('OrderStatus — urutan tahap kru tidak bisa lompat', () {
      expect(OrderStatus.ditugaskan.tahapBerikutKru, OrderStatus.dalamPerjalanan);
      expect(OrderStatus.dalamPerjalanan.tahapBerikutKru, OrderStatus.diproses);
      expect(OrderStatus.diproses.tahapBerikutKru, OrderStatus.selesai);
      expect(OrderStatus.selesai.tahapBerikutKru, isNull);
      expect(OrderStatus.menungguPembayaran.tahapBerikutKru, isNull);
    });

    test('PaymentModel — metode & statusBayar wire', () {
      final payment = PaymentModel(
        paymentId: 'p1',
        orderId: 'o1',
        userId: 'u1',
        metode: MetodeBayar.transferBank,
        jumlah: 75000,
        buktiBayar: 'https://storage/bukti.jpg',
        statusBayar: StatusBayar.menunggu,
        waktu: DateTime(2026, 7, 5, 9, 5),
      );
      final map = payment.toMap();
      expect(map['metode'], 'transfer_bank');
      expect(map['statusBayar'], 'menunggu');
      final kembali = PaymentModel.fromMap('p1', map);
      expect(kembali.metode, MetodeBayar.transferBank);
    });

    test('KruModel & ReviewModel & NotificationModel', () {
      const kru = KruModel(
        cleanerId: 'k1',
        nama: 'Andi Rahman',
        noTelepon: '081298765432',
        statusKetersediaan: true,
        rataRating: 4.9,
        posisi: GeoPoint(-2.53, 112.95),
        jumlahUlasan: 120,
      );
      expect(KruModel.fromMap('k1', kru.toMap()).rataRating, 4.9);

      final review = ReviewModel(
        reviewId: 'r1',
        orderId: 'o1',
        userId: 'u1',
        cleanerId: 'k1',
        penilaian: 5,
        komentar: 'Bersih dan rapi.',
        namaPelanggan: 'Budi Santoso',
        waktu: DateTime(2026, 7, 5),
      );
      expect(ReviewModel.fromMap('r1', review.toMap()).penilaian, 5);

      final notif = NotificationModel(
        notificationId: 'n1',
        userId: 'u1',
        judul: 'Pembayaran terverifikasi',
        pesan: 'Pesanan Anda sedang menunggu penugasan kru.',
        waktu: DateTime(2026, 7, 5),
        dibaca: false,
        orderId: 'o1',
      );
      expect(NotificationModel.fromMap('n1', notif.toMap()).dibaca, isFalse);
    });
  });
}
