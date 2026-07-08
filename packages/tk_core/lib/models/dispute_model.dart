import 'package:cloud_firestore/cloud_firestore.dart';

/// Siapa yang mengajukan banding.
enum PengajuBanding {
  kru('kru'),
  pelanggan('pelanggan');

  const PengajuBanding(this.wire);
  final String wire;
  static PengajuBanding fromWire(String? w) =>
      w == 'pelanggan' ? PengajuBanding.pelanggan : PengajuBanding.kru;
}

/// Status banding.
enum StatusBanding {
  diajukan('diajukan'),
  diterima('diterima'),
  ditolak('ditolak');

  const StatusBanding(this.wire);
  final String wire;
  static StatusBanding fromWire(String? w) =>
      StatusBanding.values.firstWhere((e) => e.wire == w,
          orElse: () => StatusBanding.diajukan);
}

/// Koleksi `disputes` — banding upah/hasil kerja. Kru atau pelanggan mengajukan
/// (alasan + bukti); admin memutus. Payout terkait DITAHAN selama banding
/// terbuka. Resolusi mencatat catatan admin (jejak audit) — tak ada pembalikan
/// diam-diam.
class DisputeModel {
  const DisputeModel({
    required this.disputeId,
    required this.orderId,
    required this.pengajuId,
    required this.pengajuNama,
    required this.pengaju,
    required this.alasan,
    required this.status,
    required this.waktu,
    this.buktiUrl,
    this.catatanAdmin = '',
    this.waktuResolusi,
  });

  final String disputeId;
  final String orderId;
  final String pengajuId;
  final String pengajuNama;
  final PengajuBanding pengaju;
  final String alasan;
  final StatusBanding status;
  final DateTime waktu;
  final String? buktiUrl;
  final String catatanAdmin;
  final DateTime? waktuResolusi;

  factory DisputeModel.fromMap(String id, Map<String, dynamic> m) =>
      DisputeModel(
        disputeId: id,
        orderId: m['orderId'] as String? ?? '',
        pengajuId: m['pengajuId'] as String? ?? '',
        pengajuNama: m['pengajuNama'] as String? ?? '',
        pengaju: PengajuBanding.fromWire(m['pengaju'] as String?),
        alasan: m['alasan'] as String? ?? '',
        status: StatusBanding.fromWire(m['status'] as String?),
        waktu: (m['waktu'] as Timestamp?)?.toDate() ?? DateTime(2000),
        buktiUrl: m['buktiUrl'] as String?,
        catatanAdmin: m['catatanAdmin'] as String? ?? '',
        waktuResolusi: (m['waktuResolusi'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'disputeId': disputeId,
        'orderId': orderId,
        'pengajuId': pengajuId,
        'pengajuNama': pengajuNama,
        'pengaju': pengaju.wire,
        'alasan': alasan,
        'status': status.wire,
        'waktu': Timestamp.fromDate(waktu),
        if (buktiUrl != null) 'buktiUrl': buktiUrl,
        'catatanAdmin': catatanAdmin,
        if (waktuResolusi != null)
          'waktuResolusi': Timestamp.fromDate(waktuResolusi!),
      };
}
