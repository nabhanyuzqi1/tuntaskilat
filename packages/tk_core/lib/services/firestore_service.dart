import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kru_model.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/pricing.dart';
import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import '../models/voucher_model.dart';
import '../seed/pricelist_seed.dart';
import '../utils/validators.dart';

/// Dilempar saat slot `jadwal` sudah terisi — transaction kedua pada slot yang
/// sama wajib gagal (skenario Black-Box #1); UI menampilkan "Jadwal Penuh".
class JadwalPenuhException implements Exception {
  const JadwalPenuhException(this.jadwal);
  final DateTime jadwal;

  @override
  String toString() => 'Jadwal Penuh';
}

/// Dilempar saat koordinat alamat di luar area layanan Kota Sampit
/// (skenario Black-Box #8 — "Out of Delivery Range").
class LuarWilayahLayananException implements Exception {
  const LuarWilayahLayananException();

  @override
  String toString() => 'Out of Delivery Range';
}

/// Dilempar saat voucher ditolak backend (kuota habis, kadaluarsa, dll).
class VoucherException implements Exception {
  const VoucherException(this.alasan);
  final VoucherTolak alasan;

  @override
  String toString() => switch (alasan) {
        VoucherTolak.tidakAda => 'Kode voucher tidak ditemukan',
        VoucherTolak.nonaktif => 'Voucher tidak aktif',
        VoucherTolak.kadaluarsa => 'Voucher sudah kedaluwarsa',
        VoucherTolak.kuotaHabis => 'Kuota voucher sudah habis',
        VoucherTolak.minimalBelanja => 'Belanja belum memenuhi minimal voucher',
      };
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _services =>
      _db.collection('services');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _kru => _db.collection('kru');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('payments');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  /// Koleksi `vouchers` — lapisan produk nyata (di luar 7 koleksi TA).
  CollectionReference<Map<String, dynamic>> get _vouchers =>
      _db.collection('vouchers');

  // ---------------------------------------------------------------- services

  Stream<List<ServiceModel>> watchActiveServices() => _services
      .where('aktif', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ServiceModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  /// Seluruh layanan termasuk nonaktif — untuk tabel A4.
  Stream<List<ServiceModel>> watchSemuaLayanan() => _services.snapshots().map(
      (s) => s.docs
          .map((d) => ServiceModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Future<ServiceModel?> getService(String serviceId) async {
    final snap = await _services.doc(serviceId).get();
    if (!snap.exists) return null;
    return ServiceModel.fromMap(snap.id, snap.data()!);
  }

  // ------------------------------------------------------------------ orders

  /// Jam slot layanan harian (P5 Hi-Fi build): 08.00, 10.00, 13.00, 15.00,
  /// 17.00, 19.00 WIB.
  static const jamSlot = [8, 10, 13, 15, 17, 19];

  /// ID dokumen order deterministik dari slot jadwal. Transaction klien tidak
  /// bisa menjalankan query, jadi kunci slot diwujudkan sebagai ID dokumen:
  /// dua pemesanan pada slot yang sama memperebutkan SATU dokumen `orders`
  /// yang sama, dan `runTransaction` menjamin hanya satu yang menang
  /// (Atomic Locking, TA Bab IV 4.2.2 — tanpa koleksi di luar 7 koleksi TA).
  static String slotOrderId(DateTime jadwal) {
    String dua(int n) => n.toString().padLeft(2, '0');
    return 'slot_${jadwal.year}${dua(jadwal.month)}${dua(jadwal.day)}'
        '${dua(jadwal.hour)}${dua(jadwal.minute)}';
  }

  /// Membuat pesanan baru lewat Firestore Transaction (Atomic Locking).
  ///
  /// - Slot `jadwal` yang sudah terisi → [JadwalPenuhException] (skenario #1).
  /// - `totalHarga`/`hargaSatuan` dihitung ulang dari dokumen `services` di
  ///   dalam transaction — angka dari klien tidak dipercaya (skenario #6).
  /// - Koordinat di luar Kota Sampit → [LuarWilayahLayananException]
  ///   (skenario #8).
  Future<OrderModel> createOrder({
    required UserModel pelanggan,
    required String serviceId,
    required DateTime jadwal,
    required num kuantitas,
    required String alamatLayanan,
    required GeoPoint lokasi,
    String catatan = '',
  }) async {
    if (kuantitas <= 0) {
      throw ArgumentError.value(kuantitas, 'kuantitas', 'harus > 0');
    }
    if (!Validators.isDalamWilayahSampit(lokasi.latitude, lokasi.longitude)) {
      throw const LuarWilayahLayananException();
    }

    final orderRef = _orders.doc(slotOrderId(jadwal));
    final serviceRef = _services.doc(serviceId);

    return _db.runTransaction<OrderModel>((tx) async {
      final slotSnap = await tx.get(orderRef);
      if (slotSnap.exists) throw JadwalPenuhException(jadwal);

      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) {
        throw StateError('Layanan $serviceId tidak ditemukan.');
      }
      final service = ServiceModel.fromMap(serviceSnap.id, serviceSnap.data()!);
      if (!service.aktif) {
        throw StateError('Layanan ${service.namaLayanan} sedang nonaktif.');
      }

      final order = OrderModel(
        orderId: orderRef.id,
        userId: pelanggan.userId,
        serviceId: serviceId,
        cleanerId: '',
        tanggalPesan: DateTime.now(),
        jadwal: jadwal,
        totalHarga: service.harga * kuantitas,
        status: OrderStatus.dibuat,
        hargaSatuan: service.harga,
        kuantitas: kuantitas,
        namaLayanan: service.namaLayanan,
        satuan: service.satuan,
        namaPelanggan: pelanggan.nama,
        teleponPelanggan: pelanggan.noTelepon,
        alamatLayanan: alamatLayanan,
        lokasi: lokasi,
        catatan: catatan,
      );
      tx.set(orderRef, order.toMap());
      return order;
    });
  }

  /// Pembuatan pesanan FINAL saat konfirmasi pembayaran (P7). Slot dikunci
  /// (Atomic Locking) di titik ini — bukan saat mengisi form — supaya draft
  /// yang ditinggalkan pelanggan tidak menyandera jadwal.
  ///
  /// Satu transaction: cek slot, hitung ulang harga dari `services`
  /// (skenario #6), tulis dokumen `orders` + `payments` sekaligus (atomik).
  /// - Non-tunai: status awal `menunggu_verifikasi`, pembayaran `menunggu`.
  /// - Tunai: status awal `menunggu_penugasan` (dibayar ke kru saat selesai),
  ///   pembayaran `menunggu` (ditandai lunas admin/kru kemudian).
  Future<OrderModel> buatPesananLengkap({
    required UserModel pelanggan,
    required String serviceId,
    required DateTime jadwal,
    required PilihanHarga pilihan,
    required String alamatLayanan,
    required GeoPoint lokasi,
    required MetodeBayar metode,
    String? voucherKode,
    String? buktiBayar,
    String catatan = '',
  }) async {
    if (!Validators.isDalamWilayahSampit(lokasi.latitude, lokasi.longitude)) {
      throw const LuarWilayahLayananException();
    }

    final orderRef = _orders.doc(slotOrderId(jadwal));
    final serviceRef = _services.doc(serviceId);
    final paymentRef = _payments.doc();
    final kode = (voucherKode ?? '').trim().toUpperCase();
    final voucherRef = kode.isEmpty ? null : _vouchers.doc(kode);
    final tunai = metode == MetodeBayar.tunai;
    final sekarang = DateTime.now();

    return _db.runTransaction<OrderModel>((tx) async {
      // Baca SEMUA dokumen dulu (aturan transaction Firestore).
      final slotSnap = await tx.get(orderRef);
      if (slotSnap.exists) throw JadwalPenuhException(jadwal);

      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) {
        throw StateError('Layanan $serviceId tidak ditemukan.');
      }
      final service = ServiceModel.fromMap(serviceSnap.id, serviceSnap.data()!);
      if (!service.aktif) {
        throw StateError('Layanan ${service.namaLayanan} sedang nonaktif.');
      }

      // Hitung ULANG subtotal dari dokumen services — jangan percaya klien.
      final hasil = service.hitungHarga(pilihan);
      if (hasil.subtotal <= 0) {
        throw ArgumentError('Pilihan harga tidak valid (subtotal 0).');
      }

      // Validasi voucher di dalam transaction (kuota/berlaku/min belanja).
      num potongan = 0;
      VoucherModel? voucher;
      if (voucherRef != null) {
        final vSnap = await tx.get(voucherRef);
        if (!vSnap.exists) throw const VoucherException(VoucherTolak.tidakAda);
        voucher = VoucherModel.fromMap(vSnap.id, vSnap.data()!);
        final r = voucher.hitungPotongan(hasil.subtotal, sekarang);
        if (r.tolak != null) throw VoucherException(r.tolak!);
        potongan = r.potongan;
      }

      final total = hasil.subtotal - potongan;
      final order = OrderModel(
        orderId: orderRef.id,
        userId: pelanggan.userId,
        serviceId: serviceId,
        cleanerId: '',
        tanggalPesan: sekarang,
        jadwal: jadwal,
        totalHarga: total,
        status: tunai
            ? OrderStatus.menungguPenugasan
            : OrderStatus.menungguVerifikasi,
        hargaSatuan: service.harga,
        kuantitas: pilihan.kuantitas,
        namaLayanan: service.namaLayanan,
        satuan: service.satuan,
        namaPelanggan: pelanggan.nama,
        teleponPelanggan: pelanggan.noTelepon,
        alamatLayanan: alamatLayanan,
        lokasi: lokasi,
        catatan: catatan,
        subtotal: hasil.subtotal,
        voucherKode: voucher?.kode ?? '',
        potongan: potongan,
        rincian: hasil.rincian,
      );
      final payment = PaymentModel(
        paymentId: paymentRef.id,
        orderId: orderRef.id,
        userId: pelanggan.userId,
        metode: metode,
        jumlah: total,
        buktiBayar: buktiBayar,
        statusBayar: StatusBayar.menunggu,
        waktu: sekarang,
      );
      tx.set(orderRef, order.toMap());
      tx.set(paymentRef, payment.toMap());
      if (voucherRef != null && voucher != null) {
        tx.update(voucherRef, {'terpakai': voucher.terpakai + 1});
      }
      return order;
    });
  }

  // ---------------------------------------------------------------- vouchers

  /// Cari voucher by kode (untuk pratinjau di klien; validasi final tetap di
  /// backend transaction). Mengembalikan null bila tak ada.
  Future<VoucherModel?> cariVoucher(String kode) async {
    final k = kode.trim().toUpperCase();
    if (k.isEmpty) return null;
    final snap = await _vouchers.doc(k).get();
    if (!snap.exists) return null;
    return VoucherModel.fromMap(snap.id, snap.data()!);
  }

  /// Seluruh voucher — untuk kelola di Panel Admin.
  Stream<List<VoucherModel>> watchVouchers() => _vouchers.snapshots().map((s) =>
      s.docs
          .map((d) => VoucherModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  /// Buat/ubah voucher (docId = kode UPPERCASE). Admin-only via Security Rules.
  Future<void> simpanVoucher(VoucherModel v) =>
      _vouchers.doc(v.kode.toUpperCase()).set(v.toMap());

  Future<void> hapusVoucher(String kode) =>
      _vouchers.doc(kode.trim().toUpperCase()).delete();

  /// Isi/overwrite katalog `services` + `vouchers` contoh sesuai pricelist TK
  /// dalam satu batch. Admin-only (Security Rules). Dipanggil dari Panel Admin.
  Future<void> seedKatalogDanVoucher() async {
    final batch = _db.batch();
    for (final s in katalogSeed()) {
      batch.set(_services.doc(s.serviceId), s.toMap());
    }
    for (final v in voucherSeed()) {
      batch.set(_vouchers.doc(v.kode.toUpperCase()), v.toMap());
    }
    await batch.commit();
  }

  /// Slot yang sudah terisi pada [hari] — untuk menampilkan slot disabled +
  /// ikon gembok di P5 (kaidah Pencegahan Kesalahan). Memakai `get` per ID
  /// slot deterministik, BUKAN query — Security Rules mengizinkan `get`
  /// dokumen order untuk pengguna masuk, sementara `list` tetap owner-only.
  Stream<Set<DateTime>> watchSlotTerisi(DateTime hari) {
    final slots = jamSlot
        .map((jam) => DateTime(hari.year, hari.month, hari.day, jam))
        .toList(growable: false);
    final streams = slots
        .map((s) => _orders.doc(slotOrderId(s)).snapshots())
        .toList(growable: false);

    late final StreamController<Set<DateTime>> controller;
    final adaDoc = List<bool>.filled(slots.length, false);
    final sudahEmit = List<bool>.filled(slots.length, false);
    final subs = <StreamSubscription<dynamic>>[];
    controller = StreamController<Set<DateTime>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          subs.add(streams[i].listen((snap) {
            adaDoc[i] = snap.exists;
            sudahEmit[i] = true;
            // Tunggu snapshot pertama SEMUA slot supaya emisi awal tidak
            // parsial (slot terisi sempat tampak kosong).
            if (sudahEmit.every((e) => e)) {
              controller.add({
                for (var j = 0; j < slots.length; j++)
                  if (adaDoc[j]) slots[j],
              });
            }
          }, onError: controller.addError));
        }
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<OrderModel> watchOrder(String orderId) => _orders
      .doc(orderId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => OrderModel.fromMap(s.id, s.data()!));

  Stream<List<OrderModel>> watchOrdersByUser(String userId) => _orders
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => OrderModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Stream<List<OrderModel>> watchOrdersByKru(String cleanerId) => _orders
      .where('cleanerId', isEqualTo: cleanerId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => OrderModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Future<void> updateOrderStatus(String orderId, OrderStatus status) =>
      _orders.doc(orderId).update({'status': status.wire});

  // --------------------------------------------------------------------- kru

  Stream<List<KruModel>> watchAvailableKru() => _kru
      .where('statusKetersediaan', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => KruModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Stream<KruModel> watchKru(String cleanerId) => _kru
      .doc(cleanerId)
      .snapshots()
      .where((s) => s.exists)
      .map((s) => KruModel.fromMap(s.id, s.data()!));

  Future<void> setKetersediaanKru(String cleanerId, bool tersedia) =>
      _kru.doc(cleanerId).update({'statusKetersediaan': tersedia});

  /// Posisi live kru saat `dalam_perjalanan` — sumber marker P8 Tracking.
  Future<void> updatePosisiKru(String cleanerId, GeoPoint posisi) =>
      _kru.doc(cleanerId).update({'posisi': posisi});

  /// K4 — laporan kerja: simpan URL foto sebelum/sesudah dan tandai order
  /// `selesai` (State Diagram 3.11: diproses → selesai).
  Future<void> submitLaporanKerja({
    required String orderId,
    required List<String> fotoSebelum,
    required List<String> fotoSesudah,
  }) =>
      _orders.doc(orderId).update({
        'fotoSebelum': fotoSebelum,
        'fotoSesudah': fotoSesudah,
        'status': OrderStatus.selesai.wire,
      });

  // ------------------------------------------------------------------- admin

  /// Semua pesanan (A2/A3) — rules `orders.list` mengizinkan admin.
  Stream<List<OrderModel>> watchSemuaOrders() => _orders.snapshots().map(
        (s) => s.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .toList(growable: false),
      );

  /// Semua kru termasuk offline (A5).
  Stream<List<KruModel>> watchSemuaKru() => _kru.snapshots().map(
        (s) => s.docs
            .map((d) => KruModel.fromMap(d.id, d.data()))
            .toList(growable: false),
      );

  /// A3 — verifikasi/tolak pembayaran (rules: `payments.update` admin-only).
  /// Skema tidak punya field alasan penolakan — alasan disampaikan lewat
  /// dokumen `notifications` ke pelanggan (mekanisme umpan balik skema).
  /// Tolak → order `ditolak` (pelanggan bisa unggah ulang, State Diagram);
  /// terima → order `terverifikasi`.
  Future<void> verifikasiPembayaran({
    required OrderModel order,
    required bool terima,
    String? alasan,
  }) async {
    // Tanpa orderBy: equality + orderBy field lain butuh composite index.
    // Payment per order praktis ≤2 (unggah ulang) — sort di klien.
    final pembayaran =
        await _payments.where('orderId', isEqualTo: order.orderId).get();
    final docs = pembayaran.docs.toList()
      ..sort((a, b) => (b.data()['waktu'] as Timestamp)
          .compareTo(a.data()['waktu'] as Timestamp));

    final batch = _db.batch();
    if (docs.isNotEmpty) {
      batch.update(docs.first.reference, {
        'statusBayar':
            (terima ? StatusBayar.terverifikasi : StatusBayar.ditolak).wire,
      });
    }
    batch.update(
      _orders.doc(order.orderId),
      {
        'status': (terima ? OrderStatus.terverifikasi : OrderStatus.ditolak)
            .wire,
      },
    );
    final notifRef = _notifications.doc();
    batch.set(notifRef, {
      'notificationId': notifRef.id,
      'userId': order.userId,
      'judul': terima
          ? 'Pembayaran terverifikasi'
          : 'Pembayaran ditolak',
      'pesan': terima
          ? 'Pesanan Anda dikonfirmasi dan sedang dijadwalkan. Terima kasih.'
          : 'Pembayaran belum terverifikasi. ${alasan ?? ''} '
              'Unggah ulang bukti transfer yang jelas.',
      'waktu': Timestamp.now(),
      'dibaca': false,
      'orderId': order.orderId,
    });
    await batch.commit();
  }

  /// A3 — penugasan kru manual: isi `cleanerId` + denormalisasi `namaKru`,
  /// status → `ditugaskan`, kabari pelanggan.
  Future<void> tugaskanKru({
    required OrderModel order,
    required KruModel kru,
  }) async {
    final batch = _db.batch();
    batch.update(_orders.doc(order.orderId), {
      'cleanerId': kru.cleanerId,
      'namaKru': kru.nama,
      'status': OrderStatus.ditugaskan.wire,
    });
    final notifRef = _notifications.doc();
    batch.set(notifRef, {
      'notificationId': notifRef.id,
      'userId': order.userId,
      'judul': 'Kru ditugaskan untuk pesanan Anda',
      'pesan': '${kru.nama} akan datang sesuai jadwal Anda. Pantau '
          'posisinya di halaman Status Pesanan.',
      'waktu': Timestamp.now(),
      'dibaca': false,
      'orderId': order.orderId,
    });
    await batch.commit();
  }

  /// A4 — tambah/ubah layanan (rules: `services.write` admin-only).
  ///
  /// Menyimpan SELURUH field (termasuk skema harga dinamis: tipeHarga, tiers,
  /// paketOpsi, addOns, kategori, gambar) — jangan membangun ulang sebagian
  /// field agar data pricing tidak terhapus saat admin menyunting layanan.
  Future<ServiceModel> simpanLayanan(ServiceModel layanan) async {
    final ref = layanan.serviceId.isEmpty
        ? _services.doc()
        : _services.doc(layanan.serviceId);
    final map = layanan.toMap()..['serviceId'] = ref.id;
    await ref.set(map);
    return ServiceModel.fromMap(ref.id, map);
  }

  Future<void> setLayananAktif(String serviceId, bool aktif) =>
      _services.doc(serviceId).update({'aktif': aktif});

  /// A5 — dokumen `kru` untuk akun kru baru (rules: `kru.create` admin).
  Future<void> buatDokumenKru(KruModel kru) =>
      _kru.doc(kru.cleanerId).set(kru.toMap());

  // ---------------------------------------------------------------- payments

  Future<PaymentModel> createPayment({
    required String orderId,
    required String userId,
    required MetodeBayar metode,
    required num jumlah,
    String? buktiBayar,
  }) async {
    final ref = _payments.doc();
    final payment = PaymentModel(
      paymentId: ref.id,
      orderId: orderId,
      userId: userId,
      metode: metode,
      jumlah: jumlah,
      buktiBayar: buktiBayar,
      statusBayar: StatusBayar.menunggu,
      waktu: DateTime.now(),
    );
    await ref.set(payment.toMap());
    return payment;
  }

  /// Unggah ulang bukti bayar untuk pesanan yang ditolak (State Diagram:
  /// ditolak ↩ upload ulang). Membuat dokumen `payments` BARU (rules:
  /// create diizinkan pemilik; update payment admin-only) lalu mengembalikan
  /// status order ke `menunggu_verifikasi`.
  Future<void> unggahUlangBukti({
    required OrderModel order,
    required String buktiBayar,
    MetodeBayar metode = MetodeBayar.transferBank,
  }) async {
    final ref = _payments.doc();
    final batch = _db.batch();
    batch.set(
      ref,
      PaymentModel(
        paymentId: ref.id,
        orderId: order.orderId,
        userId: order.userId,
        metode: metode,
        jumlah: order.totalHarga,
        buktiBayar: buktiBayar,
        statusBayar: StatusBayar.menunggu,
        waktu: DateTime.now(),
      ).toMap(),
    );
    batch.update(_orders.doc(order.orderId),
        {'status': OrderStatus.menungguVerifikasi.wire});
    await batch.commit();
  }

  // ----------------------------------------------------------------- reviews

  /// Menulis ulasan sekaligus meng-update `kru.rataRating` dan
  /// `kru.jumlahUlasan` dalam satu transaction — kewajiban skema
  /// (firestore-schema.md § reviews) selama Cloud Functions belum di-scope.
  Future<ReviewModel> createReview({
    required String orderId,
    required UserModel pelanggan,
    required String cleanerId,
    required num penilaian,
    String komentar = '',
  }) async {
    final reviewRef = _reviews.doc();
    final kruRef = _kru.doc(cleanerId);
    final orderRef = _orders.doc(orderId);

    return _db.runTransaction<ReviewModel>((tx) async {
      final kruSnap = await tx.get(kruRef);
      if (!kruSnap.exists) throw StateError('Kru $cleanerId tidak ditemukan.');
      final kru = KruModel.fromMap(kruSnap.id, kruSnap.data()!);

      final review = ReviewModel(
        reviewId: reviewRef.id,
        orderId: orderId,
        userId: pelanggan.userId,
        cleanerId: cleanerId,
        penilaian: penilaian,
        komentar: komentar,
        namaPelanggan: pelanggan.nama,
        waktu: DateTime.now(),
      );

      final jumlahBaru = kru.jumlahUlasan + 1;
      final rataBaru =
          (kru.rataRating * kru.jumlahUlasan + penilaian) / jumlahBaru;

      tx.set(reviewRef, review.toMap());
      tx.update(kruRef, {'rataRating': rataBaru, 'jumlahUlasan': jumlahBaru});
      tx.update(orderRef, {'status': OrderStatus.dinilai.wire});
      return review;
    });
  }

  /// Ulasan yang diterima seorang kru (K5) — rules `reviews.read` publik.
  Stream<List<ReviewModel>> watchReviewsByKru(String cleanerId) => _reviews
      .where('cleanerId', isEqualTo: cleanerId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ReviewModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  // ----------------------------------------------------------- notifications

  Stream<List<NotificationModel>> watchNotifications(String userId) =>
      _notifications.where('userId', isEqualTo: userId).snapshots().map(
          (s) => s.docs
              .map((d) => NotificationModel.fromMap(d.id, d.data()))
              .toList(growable: false));

  Future<void> markNotificationRead(String notificationId) =>
      _notifications.doc(notificationId).update({'dibaca': true});

  // ------------------------------------------------------------------- users

  Future<void> updateUserProfile(UserModel user) =>
      _users.doc(user.userId).update({
        'nama': user.nama,
        'noTelepon': user.noTelepon,
        'alamat': user.alamat,
      });
}
