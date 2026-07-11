import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alamat_model.dart';
import '../models/app_config_model.dart';
import '../models/kas_kru_model.dart';
import '../models/komisi_model.dart';
import '../models/kru_model.dart';
import '../models/notification_model.dart';
import '../models/dispute_model.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/payout_model.dart';
import '../models/pricing.dart';
import '../models/wage.dart';
import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
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

/// Dilempar saat kru dengan tunggakan setoran tunai melebihi batas hendak
/// ditugaskan ke order tunai (lapisan produk nyata — cegah akumulasi kas).
class KruNunggakException implements Exception {
  const KruNunggakException(this.namaKru);
  final String namaKru;

  @override
  String toString() =>
      '$namaKru masih menunggak setoran tunai — selesaikan dulu sebelum '
      'menerima order tunai baru.';
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
        VoucherTolak.hanyaPenggunaBaru =>
          'Voucher ini khusus pelanggan baru (belum pernah memesan)',
        VoucherTolak.sudahDipakaiNomor =>
          'Voucher ini sudah pernah dipakai pada nomor Anda',
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

  /// Ledger upah kru (lapisan produk nyata).
  CollectionReference<Map<String, dynamic>> get _payouts =>
      _db.collection('payouts');

  /// Banding upah/hasil kerja (lapisan produk nyata).
  CollectionReference<Map<String, dynamic>> get _disputes =>
      _db.collection('disputes');

  /// Buku kas setoran tunai per kru (lapisan produk nyata).
  CollectionReference<Map<String, dynamic>> get _kasKru =>
      _db.collection('kasKru');

  /// Riwayat setoran tunai (lapisan produk nyata).
  CollectionReference<Map<String, dynamic>> get _setoran =>
      _db.collection('setoran');

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
  static String slotOrderId(String prefix, DateTime jadwal) {
    String dua(int n) => n.toString().padLeft(2, '0');
    final p = prefix.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    return 'TK-$p-${jadwal.year}${dua(jadwal.month)}${dua(jadwal.day)}'
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

    final orderRef = _orders.doc(slotOrderId(serviceId, jadwal));
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

    final orderRef = _orders.doc(slotOrderId(serviceId, jadwal));
    final serviceRef = _services.doc(serviceId);
    final paymentRef = _payments.doc();
    final kode = (voucherKode ?? '').trim().toUpperCase();
    final voucherRef = kode.isEmpty ? null : _vouchers.doc(kode);
    final tunai = metode == MetodeBayar.tunai;
    final sekarang = DateTime.now();

    // Kunci klaim per NOMOR TELEPON (bukan uid) — mematikan trik buat akun
    // baru terus. Doc id gabungan kode + nomor ternormalisasi.
    final telepon = _normalTelp(pelanggan.noTelepon);
    final usageRef = voucherRef == null
        ? null
        : _db.collection('voucherUsages').doc('${kode}__$telepon');

    // Cek "khusus pengguna baru" DI LUAR transaction (query tak boleh di dalam
    // transaction). Peek voucher dulu; bila new-user-only & user sudah pernah
    // memesan → tolak.
    if (voucherRef != null) {
      final vPeek = await voucherRef.get();
      if (vPeek.exists) {
        final v = VoucherModel.fromMap(vPeek.id, vPeek.data()!);
        if (v.khususPenggunaBaru) {
          final adaOrder = await _orders
              .where('userId', isEqualTo: pelanggan.userId)
              .limit(1)
              .get();
          if (adaOrder.docs.isNotEmpty) {
            throw const VoucherException(VoucherTolak.hanyaPenggunaBaru);
          }
        }
      }
    }

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

      // Validasi voucher di dalam transaction (kuota/berlaku/min belanja +
      // kunci per-nomor).
      num potongan = 0;
      VoucherModel? voucher;
      if (voucherRef != null) {
        final vSnap = await tx.get(voucherRef);
        if (!vSnap.exists) throw const VoucherException(VoucherTolak.tidakAda);
        voucher = VoucherModel.fromMap(vSnap.id, vSnap.data()!);
        if (voucher.sekaliPerNomor && usageRef != null) {
          final uSnap = await tx.get(usageRef);
          if (uSnap.exists) {
            throw const VoucherException(VoucherTolak.sudahDipakaiNomor);
          }
        }
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
        metodePembayaran: metode,
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
        // Catat pemakaian per-nomor (kunci anti akun-baru-berulang).
        if (voucher.sekaliPerNomor && usageRef != null) {
          tx.set(usageRef, {
            'kode': voucher.kode,
            'telepon': telepon,
            'userId': pelanggan.userId,
            'waktu': Timestamp.fromDate(sekarang),
          });
        }
      }
      return order;
    });
  }

  // -------------------------------------------------------- 2FA admin (TOTP)

  /// Daftar akun admin (A6 Manajemen Tim). Rules: users.list admin-only.
  Stream<List<UserModel>> watchAdmins() => _users
      .where('role', isEqualTo: 'admin')
      .snapshots()
      .map((s) => s.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  /// Ambil konfigurasi 2FA admin: (secret, aktif). null bila belum diatur.
  Future<({String secret, bool aktif})?> get2fa(String uid) async {
    final snap = await _db.collection('admin2fa').doc(uid).get();
    if (!snap.exists) return null;
    final d = snap.data()!;
    return (
      secret: d['secret'] as String? ?? '',
      aktif: d['aktif'] as bool? ?? false,
    );
  }

  /// Simpan/aktifkan 2FA admin (secret base32 + status). Rahasia hanya bisa
  /// dibaca/ditulis pemilik akun (rules).
  Future<void> set2fa(String uid, String secret, bool aktif) =>
      _db.collection('admin2fa').doc(uid).set({
        'secret': secret,
        'aktif': aktif,
      });

  /// Normalisasi nomor telepon jadi kunci konsisten (buang non-digit, 0→62).
  static String _normalTelp(String no) {
    var d = no.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('0')) d = '62${d.substring(1)}';
    return d;
  }

  /// Admin membatalkan penugasan kru (A3) — order kembali ke antrean
  /// "menunggu penugasan" agar bisa ditugaskan ulang. Hanya untuk order yang
  /// belum mulai dikerjakan (ditugaskan/dalam perjalanan).
  Future<void> batalkanPenugasan(String orderId) => _orders.doc(orderId).update({
        'cleanerId': '',
        'kruIds': <String>[],
        'namaKru': FieldValue.delete(),
        'penugasan': FieldValue.delete(),
        'status': OrderStatus.menungguPenugasan.wire,
      });

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
  Stream<Set<DateTime>> watchSlotTerisi(String serviceId, DateTime hari) {
    final slots = jamSlot
        .map((jam) => DateTime(hari.year, hari.month, hari.day, jam))
        .toList(growable: false);
    final streams = slots
        .map((s) => _orders.doc(slotOrderId(serviceId, s)).snapshots())
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

  /// Order aktif terbaru milik pelanggan (untuk kartu "order berjalan" di
  /// Beranda, pola Gojek). null bila tak ada yang aktif.
  Stream<OrderModel?> watchOrderAktif(String userId) => _orders
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((s) {
        final aktif = s.docs
            .map((d) => OrderModel.fromMap(d.id, d.data()))
            .where((o) => const {
                  OrderStatus.menungguVerifikasi,
                  OrderStatus.terverifikasi,
                  OrderStatus.menungguPenugasan,
                  OrderStatus.ditugaskan,
                  OrderStatus.dalamPerjalanan,
                  OrderStatus.diproses,
                }.contains(o.status))
            .toList()
          ..sort((a, b) => b.tanggalPesan.compareTo(a.tanggalPesan));
        return aktif.isEmpty ? null : aktif.first;
      });

  /// Pelanggan membatalkan pesanan (hanya sebelum kru bekerja). Rules
  /// mengizinkan pemilik mengubah `status`.
  Future<void> batalkanPesanan(OrderModel order) {
    if (!order.status.bisaDibatalkanPelanggan) {
      throw StateError('Pesanan tidak dapat dibatalkan pada tahap ini.');
    }
    return _orders
        .doc(order.orderId)
        .update({'status': OrderStatus.dibatalkan.wire});
  }

  // ------------------------------------------------------- alamat tersimpan

  CollectionReference<Map<String, dynamic>> _alamatCol(String uid) =>
      _users.doc(uid).collection('alamat');

  Stream<List<AlamatModel>> watchAlamat(String uid) =>
      _alamatCol(uid).snapshots().map((s) => s.docs
          .map((d) => AlamatModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  Future<void> simpanAlamat(String uid, AlamatModel a) => a.id.isEmpty
      ? _alamatCol(uid).add(a.toMap())
      : _alamatCol(uid).doc(a.id).set(a.toMap());

  Future<void> hapusAlamat(String uid, String id) =>
      _alamatCol(uid).doc(id).delete();

  /// Order yang menugaskan kru ini (worker ATAU helper) — pakai `kruIds`
  /// array-contains agar helper juga melihat pekerjaannya. Digabung dengan
  /// query `cleanerId` untuk order LAMA yang belum punya field `kruIds`.
  Stream<List<OrderModel>> watchOrdersByKru(String cleanerId) {
    final byKruIds = _orders.where('kruIds', arrayContains: cleanerId);
    final byCleaner = _orders.where('cleanerId', isEqualTo: cleanerId);

    final controller = StreamController<List<OrderModel>>();
    final terkini = <int, Map<String, OrderModel>>{0: {}, 1: {}};
    final sudahEmit = [false, false];

    void emit() {
      // Emisi pertama menunggu kedua query supaya daftar tak "kedip".
      if (!sudahEmit.every((e) => e)) return;
      final gabung = <String, OrderModel>{}
        ..addAll(terkini[0]!)
        ..addAll(terkini[1]!);
      controller.add(gabung.values.toList(growable: false));
    }

    final subs = <StreamSubscription>[];
    for (final (i, q) in [byKruIds, byCleaner].indexed) {
      subs.add(q.snapshots().listen((s) {
        terkini[i] = {
          for (final d in s.docs) d.id: OrderModel.fromMap(d.id, d.data())
        };
        sudahEmit[i] = true;
        emit();
      }, onError: controller.addError));
    }
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }

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

  /// Foto profil kru (K6) — wajib bagi kru aktif.
  Future<void> updateFotoKru(String cleanerId, String fotoUrl) =>
      _kru.doc(cleanerId).update({'fotoUrl': fotoUrl});

  /// K4 — laporan kerja: simpan URL foto sebelum/sesudah dan tandai order
  /// `selesai` (State Diagram 3.11: diproses → selesai).
  Future<void> submitLaporanKerja({
    required String orderId,
    required List<String> fotoSebelum,
    required List<String> fotoSesudah,
    KonfigUpah? konfig,
  }) async {
    // Komisi: pakai override bila diberikan (tes), selain itu baca settings.
    final KonfigKomisi? cfgKomisi = konfig == null ? await getKomisi() : null;
    final orderRef = _orders.doc(orderId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(orderRef);
      if (!snap.exists) throw StateError('Order tidak ditemukan.');
      final order = OrderModel.fromMap(snap.id, snap.data()!);

      // Idempoten: bila sudah selesai/dinilai, jangan bukukan ulang (mencegah
      // kas tunai & payout tercatat dobel).
      if (order.status == OrderStatus.selesai ||
          order.status == OrderStatus.dinilai) {
        return;
      }

      final konfigUpah =
          konfig ?? cfgKomisi!.upahUntuk(order.serviceId);
      final String leadNama = order.penugasan.isNotEmpty
          ? order.penugasan.first.nama
          : (order.namaKru ?? 'Kru');

      // Update Order → selesai.
      tx.update(orderRef, {
        'fotoSebelum': fotoSebelum,
        'fotoSesudah': fotoSesudah,
        'status': OrderStatus.selesai.wire,
      });

      // Hitung & simpan Payout (server-truthed juga oleh onOrderFinalize).
      // Pembukuan kas tunai TIDAK dilakukan di sini: kru tak boleh menulis buku
      // kasnya sendiri. Cloud Function onOrderFinalize (admin SDK) yang mencatat
      // komisi tunai ke kasKru saat order tunai selesai.
      if (order.penugasan.isNotEmpty) {
        final hasil =
            bagiUpah(order.totalHarga, order.penugasan, konfig: konfigUpah);
        for (final p in order.penugasan) {
          final payRef = _payouts.doc('${orderId}_${p.cleanerId}');
          tx.set(
              payRef,
              PayoutModel(
                payoutId: payRef.id,
                orderId: orderId,
                cleanerId: p.cleanerId,
                namaKru: p.nama,
                peran: p.peran,
                jumlah: hasil.bagian[p.cleanerId] ?? 0,
                status: StatusPayout.pending,
                waktu: DateTime.now(),
              ).toMap());
        }
      } else {
        // Fallback untuk pesanan lama (single cleaner tanpa `penugasan`)
        final payRef = _payouts.doc('${orderId}_${order.cleanerId}');
        final komisi =
            (order.totalHarga * konfigUpah.komisiPersen / 100).round();
        tx.set(
            payRef,
            PayoutModel(
              payoutId: payRef.id,
              orderId: orderId,
              cleanerId: order.cleanerId,
              namaKru: leadNama,
              peran: PeranKru.worker,
              jumlah: order.totalHarga - komisi,
              status: StatusPayout.pending,
              waktu: DateTime.now(),
            ).toMap());
      }
    });
  }

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

  /// A3 — penugasan kru tunggal. Delegasi ke [tugaskanKruMulti] agar SEMUA
  /// jalur penugasan mengisi `penugasan` + `kruIds` (payout & visibilitas
  /// portal Kru bergantung pada keduanya).
  Future<void> tugaskanKru({
    required OrderModel order,
    required KruModel kru,
  }) =>
      tugaskanKruMulti(order: order, penugasan: [
        Penugasan(
            cleanerId: kru.cleanerId, nama: kru.nama, peran: PeranKru.worker),
      ]);

  // ------------------------------------------------- penugasan multi-kru

  /// A3 — penugasan MULTI kru (worker + helper). Isi `penugasan` + `kruIds`,
  /// `cleanerId`/`namaKru` = lead (worker pertama, kompatibel), status →
  /// `ditugaskan`. Menolak bila jumlah kru < [minPetugas] (dari paket).
  Future<void> tugaskanKruMulti({
    required OrderModel order,
    required List<Penugasan> penugasan,
    int minPetugas = 1,
  }) async {
    if (penugasan.isEmpty) {
      throw ArgumentError('Minimal satu kru harus ditugaskan.');
    }
    if (penugasan.length < minPetugas) {
      throw ArgumentError(
          'Layanan ini butuh $minPetugas petugas, baru ${penugasan.length}.');
    }
    final ids = penugasan.map((p) => p.cleanerId).toList();
    if (ids.toSet().length != ids.length) {
      throw ArgumentError('Kru tidak boleh ganda dalam satu order.');
    }
    // Lead = worker pertama bila ada, jika tidak kru pertama.
    final lead = penugasan.firstWhere((p) => p.peran == PeranKru.worker,
        orElse: () => penugasan.first);

    // Guard setoran tunai: lead pemegang kas tak boleh nunggak di atas batas
    // saat ditugaskan ke order tunai.
    if (order.tunai && !await bolehTerimaTunai(lead.cleanerId)) {
      throw KruNunggakException(lead.nama);
    }

    final batch = _db.batch();
    batch.update(_orders.doc(order.orderId), {
      'penugasan': penugasan.map((p) => p.toMap()).toList(),
      'kruIds': ids,
      'cleanerId': lead.cleanerId,
      'namaKru': lead.nama,
      'status': OrderStatus.ditugaskan.wire,
    });
    final notifRef = _notifications.doc();
    final labelKru = penugasan.length == 1
        ? lead.nama
        : '${lead.nama} + ${penugasan.length - 1} kru lain';
    batch.set(notifRef, {
      'notificationId': notifRef.id,
      'userId': order.userId,
      'judul': 'Kru ditugaskan untuk pesanan Anda',
      'pesan': '$labelKru akan datang sesuai jadwal Anda. Pantau di '
          'halaman Status Pesanan.',
      'waktu': Timestamp.now(),
      'dibaca': false,
      'orderId': order.orderId,
    });
    // Notifikasi untuk SETIAP kru tertugas (in-app list + fallback bila FCM
    // gagal; Cloud Function mengirim push FCM ke token mereka).
    for (final p in penugasan) {
      final kn = _notifications.doc();
      batch.set(kn, {
        'notificationId': kn.id,
        'userId': p.cleanerId,
        'judul': 'Tugas baru untuk Anda',
        'pesan': '${order.namaLayanan} — ${order.alamatLayanan}. '
            'Buka aplikasi untuk detail & navigasi.',
        'waktu': Timestamp.now(),
        'dibaca': false,
        'orderId': order.orderId,
      });
    }
    await batch.commit();
  }

  /// Simpan/hapus token FCM perangkat kru (dipanggil saat login/logout).
  Future<void> simpanFcmTokenKru(String cleanerId, String token) =>
      _kru.doc(cleanerId).update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });

  Future<void> hapusFcmTokenKru(String cleanerId, String token) =>
      _kru.doc(cleanerId).update({
        'fcmTokens': FieldValue.arrayRemove([token])
      });



  /// Payout milik seorang kru (portal Kru — upah saya).
  Stream<List<PayoutModel>> watchPayoutsByKru(String cleanerId) => _payouts
      .where('cleanerId', isEqualTo: cleanerId)
      .snapshots()
      .map((s) => s.docs
          .map((d) => PayoutModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  /// Seluruh payout (Panel Admin).
  Stream<List<PayoutModel>> watchSemuaPayouts() => _payouts.snapshots().map(
      (s) => s.docs
          .map((d) => PayoutModel.fromMap(d.id, d.data()))
          .toList(growable: false));

  /// Tandai payout sudah dibayar (admin).
  Future<void> tandaiPayoutDibayar(String payoutId) =>
      _payouts.doc(payoutId).update({'status': StatusPayout.dibayar.wire});

  // ------------------------------------------------------------- banding

  /// Ajukan banding (kru/pelanggan). Payout terkait order DITAHAN selama
  /// banding terbuka (dalam satu transaction, jadi konsisten).
  Future<void> ajukanBanding({
    required String orderId,
    required String pengajuId,
    required String pengajuNama,
    required PengajuBanding pengaju,
    required String alasan,
    String? buktiUrl,
  }) async {
    final dispRef = _disputes.doc();
    final payoutSnap =
        await _payouts.where('orderId', isEqualTo: orderId).get();
    final batch = _db.batch();
    batch.set(
        dispRef,
        DisputeModel(
          disputeId: dispRef.id,
          orderId: orderId,
          pengajuId: pengajuId,
          pengajuNama: pengajuNama,
          pengaju: pengaju,
          alasan: alasan,
          status: StatusBanding.diajukan,
          waktu: DateTime.now(),
          buktiUrl: buktiUrl,
        ).toMap());
    for (final d in payoutSnap.docs) {
      batch.update(d.reference, {'status': StatusPayout.ditahan.wire});
    }
    await batch.commit();
  }

  /// Admin memutus banding: catat keputusan (+catatan audit) & lepas tahanan
  /// payout (kembali `pending`). Penyesuaian jumlah dilakukan admin terpisah
  /// bila diterima — tidak ada pembalikan diam-diam.
  Future<void> tanganiBanding({
    required DisputeModel banding,
    required bool diterima,
    required String catatanAdmin,
  }) async {
    final payoutSnap =
        await _payouts.where('orderId', isEqualTo: banding.orderId).get();
    final batch = _db.batch();
    batch.update(_disputes.doc(banding.disputeId), {
      'status':
          (diterima ? StatusBanding.diterima : StatusBanding.ditolak).wire,
      'catatanAdmin': catatanAdmin,
      'waktuResolusi': Timestamp.now(),
    });
    for (final d in payoutSnap.docs) {
      batch.update(d.reference, {'status': StatusPayout.pending.wire});
    }
    await batch.commit();
  }

  /// Banding milik seorang kru / seluruhnya (admin).
  Stream<List<DisputeModel>> watchDisputes() => _disputes.snapshots().map(
      (s) => s.docs
          .map((d) => DisputeModel.fromMap(d.id, d.data()))
          .toList(growable: false));

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

  /// A5 — ubah profil kru (keahlian, tipe, nama, telepon) tanpa menimpa
  /// field runtime (posisi/token/rating). Merge sebagian.
  Future<void> updateProfilKru(
    String cleanerId, {
    String? nama,
    String? noTelepon,
    List<String>? keahlian,
    KruTipe? tipe,
  }) =>
      _kru.doc(cleanerId).update({
        'nama': ?nama,
        'noTelepon': ?noTelepon,
        'keahlian': ?keahlian,
        'tipe': ?tipe?.wire,
      });

  /// A5 — set status kepegawaian kru (aktif/nonaktif/diberhentikan). Kru
  /// nonaktif/diberhentikan otomatis di-offline-kan agar hilang dari daftar.
  Future<void> setStatusKru(String cleanerId, StatusKru status) =>
      _kru.doc(cleanerId).update({
        'status': status.wire,
        if (!status.bisaDitugaskan) 'statusKetersediaan': false,
      });

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
        'fotoUrl': user.fotoUrl,
      });

  // ------------------------------------------------------------------- chat

  /// Kirim pesan chat ke subkoleksi `messages` pada dokumen `orders`.
  Future<void> kirimPesanChat(String orderId, MessageModel message) async {
    final ref = _orders.doc(orderId).collection('messages').doc(message.id);
    await ref.set(message.toMap());
  }

  /// Pantau pesan chat pada pesanan tertentu secara real-time.
  Stream<List<MessageModel>> watchChatMessages(String orderId) => _orders
      .doc(orderId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => MessageModel.fromFirestore(d))
          .toList(growable: false));

  // ------------------------------------------------------------------- settings
  
  Stream<Map<String, dynamic>> watchSettings(String docId) =>
      _db.collection('settings').doc(docId).snapshots().map((s) => s.data() ?? {});

  Future<void> updateSettings(String docId, Map<String, dynamic> data) async {
    await _db.collection('settings').doc(docId).set(data, SetOptions(merge: true));
  }

  // --------------------------------------------------------------- app config

  /// Konfigurasi runtime app (settings/app) untuk maintenance/update paksa.
  Stream<KonfigApp> watchKonfigApp() => _db
      .collection('settings')
      .doc('app')
      .snapshots()
      .map((s) => KonfigApp.fromMap(s.data() ?? const {}));

  // -------------------------------------------------------------------- komisi

  /// Konfigurasi komisi (settings/komisi). Default bila belum diatur.
  Stream<KonfigKomisi> watchKomisi() => _db
      .collection('settings')
      .doc('komisi')
      .snapshots()
      .map((s) => KonfigKomisi.fromMap(s.data() ?? const {}));

  Future<KonfigKomisi> getKomisi() async {
    final s = await _db.collection('settings').doc('komisi').get();
    return KonfigKomisi.fromMap(s.data() ?? const {});
  }

  Future<void> simpanKomisi(KonfigKomisi k) async {
    await _db
        .collection('settings')
        .doc('komisi')
        .set(k.toMap(), SetOptions(merge: false));
  }

  // ---------------------------------------------------------------- kas tunai

  /// Buku kas satu kru (K6/dashboard kru). Doc mungkin belum ada → default 0.
  Stream<KasKru> watchKas(String cleanerId) =>
      _kasKru.doc(cleanerId).snapshots().map(
            (s) => s.exists
                ? KasKru.fromMap(s.id, s.data()!)
                : KasKru(cleanerId: cleanerId),
          );

  /// Seluruh buku kas (panel admin Setoran).
  Stream<List<KasKru>> watchSemuaKas() => _kasKru.snapshots().map(
        (s) => s.docs
            .map((d) => KasKru.fromMap(d.id, d.data()))
            .toList(growable: false),
      );

  /// Apakah kru boleh menerima order tunai (saldo ≤ batas). Doc absen → boleh.
  Future<bool> bolehTerimaTunai(String cleanerId) async {
    final s = await _kasKru.doc(cleanerId).get();
    if (!s.exists) return true;
    return KasKru.fromMap(s.id, s.data()!).bolehTerimaTunai;
  }

  /// Admin menerima setoran tunai dari kru. Atomik: kurangi saldoTunai (tak
  /// boleh minus), tambah totalSetor, catat riwayat `setoran/`.
  Future<void> terimaSetoran({
    required String cleanerId,
    required String namaKru,
    required int jumlah,
    required String adminUid,
    String catatan = '',
  }) async {
    if (jumlah <= 0) throw ArgumentError('Jumlah setoran harus > 0.');
    final kasRef = _kasKru.doc(cleanerId);
    final setoranRef = _setoran.doc();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(kasRef);
      final kas = snap.exists
          ? KasKru.fromMap(snap.id, snap.data()!)
          : KasKru(cleanerId: cleanerId, namaKru: namaKru);
      if (jumlah > kas.saldoTunai) {
        throw StateError(
            'Setoran (Rp$jumlah) melebihi saldo tunai kru (Rp${kas.saldoTunai}).');
      }
      tx.set(
        kasRef,
        {
          'cleanerId': cleanerId,
          'namaKru': namaKru.isEmpty ? kas.namaKru : namaKru,
          'saldoTunai': kas.saldoTunai - jumlah,
          'batasNunggak': kas.batasNunggak,
          'totalMasuk': kas.totalMasuk,
          'totalSetor': kas.totalSetor + jumlah,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        setoranRef,
        SetoranModel(
          setoranId: setoranRef.id,
          cleanerId: cleanerId,
          namaKru: namaKru,
          jumlah: jumlah,
          diterimaOleh: adminUid,
          waktu: DateTime.now(),
          catatan: catatan,
        ).toMap(),
      );
    });
  }

  /// Riwayat setoran (admin). Diurutkan terbaru dulu di klien.
  Stream<List<SetoranModel>> watchSetoran() => _setoran.snapshots().map(
        (s) => (s.docs
                .map((d) => SetoranModel.fromMap(d.id, d.data()))
                .toList()
              ..sort((a, b) => b.waktu.compareTo(a.waktu)))
            .toList(growable: false),
      );
}
