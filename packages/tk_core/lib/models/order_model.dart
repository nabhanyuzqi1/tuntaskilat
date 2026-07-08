import 'package:cloud_firestore/cloud_firestore.dart';

import 'pricing.dart';
import 'wage.dart';

/// Status pesanan sesuai State Diagram (Gambar 3.11 TA):
/// dibuat → menunggu_pembayaran → menunggu_verifikasi →
/// (ditolak ↩ upload ulang | terverifikasi) → menunggu_penugasan →
/// ditugaskan → dalam_perjalanan → diproses → selesai → dinilai.
enum OrderStatus {
  dibuat('dibuat'),
  menungguPembayaran('menunggu_pembayaran'),
  menungguVerifikasi('menunggu_verifikasi'),
  ditolak('ditolak'),
  terverifikasi('terverifikasi'),
  menungguPenugasan('menunggu_penugasan'),
  ditugaskan('ditugaskan'),
  dalamPerjalanan('dalam_perjalanan'),
  diproses('diproses'),
  selesai('selesai'),
  dinilai('dinilai');

  const OrderStatus(this.wire);

  /// Nilai string yang tersimpan di field `status`.
  final String wire;

  static OrderStatus fromWire(String value) =>
      OrderStatus.values.firstWhere((s) => s.wire == value);

  /// Tahap berikutnya yang boleh dituju kru dari K3 (status tak bisa lompat
  /// tahap — kaidah Pencegahan Kesalahan).
  OrderStatus? get tahapBerikutKru => switch (this) {
        OrderStatus.ditugaskan => OrderStatus.dalamPerjalanan,
        OrderStatus.dalamPerjalanan => OrderStatus.diproses,
        OrderStatus.diproses => OrderStatus.selesai,
        _ => null,
      };
}

/// Koleksi `orders` — koleksi inti, pusat Atomic Locking (lihat PRD §7).
class OrderModel {
  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.serviceId,
    required this.cleanerId,
    required this.tanggalPesan,
    required this.jadwal,
    required this.totalHarga,
    required this.status,
    required this.hargaSatuan,
    required this.kuantitas,
    required this.namaLayanan,
    required this.satuan,
    required this.namaPelanggan,
    required this.teleponPelanggan,
    this.namaKru,
    required this.alamatLayanan,
    this.lokasi,
    required this.catatan,
    this.fotoSebelum = const [],
    this.fotoSesudah = const [],
    this.subtotal = 0,
    this.voucherKode = '',
    this.potongan = 0,
    this.rincian = const [],
    this.penugasan = const [],
    this.kruIds = const [],
  });

  final String orderId;
  final String userId;
  final String serviceId;

  /// Kosong ('') sebelum ditugaskan admin.
  final String cleanerId;
  final DateTime tanggalPesan;

  /// Jadwal kedatangan kru — field yang dikunci Atomic Locking.
  final DateTime jadwal;

  /// Hasil kalkulasi `services.harga × kuantitas`, divalidasi ulang di backend.
  final num totalHarga;
  final OrderStatus status;

  /// Tarif per unit saat dipesan (denormalisasi harga tetap).
  final num hargaSatuan;

  /// Jumlah jam/ruangan/m².
  final num kuantitas;
  final String namaLayanan;
  final String satuan;
  final String namaPelanggan;
  final String teleponPelanggan;
  final String? namaKru;
  final String alamatLayanan;
  final GeoPoint? lokasi;
  final String catatan;
  final List<String> fotoSebelum;
  final List<String> fotoSesudah;

  /// Harga sebelum potongan voucher (produk nyata; di TA totalHarga = subtotal).
  final num subtotal;

  /// Kode voucher yang dipakai ('' bila tak ada).
  final String voucherKode;

  /// Potongan dari voucher (Rupiah). `totalHarga = subtotal - potongan`.
  final num potongan;

  /// Rincian baris harga (paket/durasi/add-on/luas) untuk ditampilkan.
  final List<BarisRincian> rincian;

  /// Penugasan multi-kru (worker + helper). `cleanerId` = lead (kompatibel).
  /// Kosong untuk order lama bertugas tunggal.
  final List<Penugasan> penugasan;

  /// ID semua kru tertugas — untuk query `array-contains` di portal Kru.
  final List<String> kruIds;

  /// True bila semua kru tertugas sudah konfirmasi "selesai bagian saya".
  bool get semuaKruKonfirmasi =>
      penugasan.isNotEmpty && penugasan.every((p) => p.sudahKonfirmasi);

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) => OrderModel(
        orderId: id,
        userId: map['userId'] as String? ?? '',
        serviceId: map['serviceId'] as String? ?? '',
        cleanerId: map['cleanerId'] as String? ?? '',
        tanggalPesan: (map['tanggalPesan'] as Timestamp).toDate(),
        jadwal: (map['jadwal'] as Timestamp).toDate(),
        totalHarga: map['totalHarga'] as num? ?? 0,
        status: OrderStatus.fromWire(map['status'] as String),
        hargaSatuan: map['hargaSatuan'] as num? ?? 0,
        kuantitas: map['kuantitas'] as num? ?? 0,
        namaLayanan: map['namaLayanan'] as String? ?? '',
        satuan: map['satuan'] as String? ?? '',
        namaPelanggan: map['namaPelanggan'] as String? ?? '',
        teleponPelanggan: map['teleponPelanggan'] as String? ?? '',
        namaKru: map['namaKru'] as String?,
        alamatLayanan: map['alamatLayanan'] as String? ?? '',
        lokasi: map['lokasi'] as GeoPoint?,
        catatan: map['catatan'] as String? ?? '',
        fotoSebelum:
            (map['fotoSebelum'] as List?)?.cast<String>() ?? const [],
        fotoSesudah:
            (map['fotoSesudah'] as List?)?.cast<String>() ?? const [],
        subtotal: map['subtotal'] as num? ?? map['totalHarga'] as num? ?? 0,
        voucherKode: map['voucherKode'] as String? ?? '',
        potongan: map['potongan'] as num? ?? 0,
        rincian: ((map['rincian'] as List?) ?? [])
            .map((e) =>
                BarisRincian.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        penugasan: ((map['penugasan'] as List?) ?? [])
            .map((e) =>
                Penugasan.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
        kruIds: (map['kruIds'] as List?)?.cast<String>() ?? const [],
      );

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'userId': userId,
        'serviceId': serviceId,
        'cleanerId': cleanerId,
        'tanggalPesan': Timestamp.fromDate(tanggalPesan),
        'jadwal': Timestamp.fromDate(jadwal),
        'totalHarga': totalHarga,
        'status': status.wire,
        'hargaSatuan': hargaSatuan,
        'kuantitas': kuantitas,
        'namaLayanan': namaLayanan,
        'satuan': satuan,
        'namaPelanggan': namaPelanggan,
        'teleponPelanggan': teleponPelanggan,
        'namaKru': namaKru,
        'alamatLayanan': alamatLayanan,
        'lokasi': lokasi,
        'catatan': catatan,
        'fotoSebelum': fotoSebelum,
        'fotoSesudah': fotoSesudah,
        'subtotal': subtotal,
        'voucherKode': voucherKode,
        'potongan': potongan,
        'rincian': rincian.map((e) => e.toMap()).toList(),
        'penugasan': penugasan.map((e) => e.toMap()).toList(),
        'kruIds': kruIds,
      };
}
