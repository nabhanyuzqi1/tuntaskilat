import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/kru_model.dart';
import '../models/notification_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
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

  // ---------------------------------------------------------------- services

  Stream<List<ServiceModel>> watchActiveServices() => _services
      .where('aktif', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => ServiceModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Future<ServiceModel?> getService(String serviceId) async {
    final snap = await _services.doc(serviceId).get();
    if (!snap.exists) return null;
    return ServiceModel.fromMap(snap.id, snap.data()!);
  }

  // ------------------------------------------------------------------ orders

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
