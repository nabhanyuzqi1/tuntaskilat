import 'package:cloud_firestore/cloud_firestore.dart';

import 'wage.dart';

/// Status pencairan upah kru.
enum StatusPayout {
  pending('pending'), // sudah dihitung, menunggu dibayar
  dibayar('dibayar'),
  ditahan('ditahan'); // ditahan karena ada banding

  const StatusPayout(this.wire);
  final String wire;
  static StatusPayout fromWire(String? w) =>
      StatusPayout.values.firstWhere((e) => e.wire == w,
          orElse: () => StatusPayout.pending);
}

/// Koleksi `payouts` — ledger upah per (order, kru). Dibuat backend saat order
/// selesai; IMUTABEL bagi kru. Hanya admin yang mengubah status/jumlah, dan
/// hanya lewat resolusi banding (jejak audit). Uang tak pernah dipercaya klien.
class PayoutModel {
  const PayoutModel({
    required this.payoutId,
    required this.orderId,
    required this.cleanerId,
    required this.namaKru,
    required this.peran,
    required this.jumlah,
    required this.status,
    required this.waktu,
  });

  final String payoutId;
  final String orderId;
  final String cleanerId;
  final String namaKru;
  final PeranKru peran;
  final num jumlah;
  final StatusPayout status;
  final DateTime waktu;

  factory PayoutModel.fromMap(String id, Map<String, dynamic> m) => PayoutModel(
        payoutId: id,
        orderId: m['orderId'] as String? ?? '',
        cleanerId: m['cleanerId'] as String? ?? '',
        namaKru: m['namaKru'] as String? ?? '',
        peran: PeranKru.fromWire(m['peran'] as String?),
        jumlah: m['jumlah'] as num? ?? 0,
        status: StatusPayout.fromWire(m['status'] as String?),
        waktu: (m['waktu'] as Timestamp?)?.toDate() ?? DateTime(2000),
      );

  Map<String, dynamic> toMap() => {
        'payoutId': payoutId,
        'orderId': orderId,
        'cleanerId': cleanerId,
        'namaKru': namaKru,
        'peran': peran.wire,
        'jumlah': jumlah,
        'status': status.wire,
        'waktu': Timestamp.fromDate(waktu),
      };
}
