import 'package:cloud_firestore/cloud_firestore.dart';

enum MetodeBayar {
  transferBank('transfer_bank'),
  qris('qris'),
  tunai('tunai');

  const MetodeBayar(this.wire);
  final String wire;

  static MetodeBayar fromWire(String value) =>
      MetodeBayar.values.firstWhere((m) => m.wire == value);
}

enum StatusBayar {
  menunggu('menunggu'),
  terverifikasi('terverifikasi'),
  ditolak('ditolak');

  const StatusBayar(this.wire);
  final String wire;

  static StatusBayar fromWire(String value) =>
      StatusBayar.values.firstWhere((s) => s.wire == value);
}

/// Koleksi `payments` — lihat firestore-schema.md. MVP: unggah bukti manual +
/// verifikasi admin (payment gateway otomatis di luar scope).
class PaymentModel {
  const PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.userId,
    required this.metode,
    required this.jumlah,
    this.buktiBayar,
    required this.statusBayar,
    required this.waktu,
  });

  final String paymentId;
  final String orderId;
  final String userId;
  final MetodeBayar metode;
  final num jumlah;

  /// URL di Firebase Storage; null jika tunai.
  final String? buktiBayar;
  final StatusBayar statusBayar;
  final DateTime waktu;

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) =>
      PaymentModel(
        paymentId: id,
        orderId: map['orderId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        metode: MetodeBayar.fromWire(map['metode'] as String),
        jumlah: map['jumlah'] as num? ?? 0,
        buktiBayar: map['buktiBayar'] as String?,
        statusBayar: StatusBayar.fromWire(map['statusBayar'] as String),
        waktu: (map['waktu'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'paymentId': paymentId,
        'orderId': orderId,
        'userId': userId,
        'metode': metode.wire,
        'jumlah': jumlah,
        'buktiBayar': buktiBayar,
        'statusBayar': statusBayar.wire,
        'waktu': Timestamp.fromDate(waktu),
      };
}
