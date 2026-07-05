import 'package:cloud_firestore/cloud_firestore.dart';

/// Koleksi `reviews` — lihat firestore-schema.md. Menulis dokumen baru WAJIB
/// memicu update `kru.rataRating` dan `kru.jumlahUlasan` (via transaction di
/// FirestoreService.createReview selama Cloud Functions belum di-scope).
class ReviewModel {
  const ReviewModel({
    required this.reviewId,
    required this.orderId,
    required this.userId,
    required this.cleanerId,
    required this.penilaian,
    required this.komentar,
    required this.namaPelanggan,
    required this.waktu,
  });

  final String reviewId;
  final String orderId;

  /// Penulis ulasan.
  final String userId;

  /// Kru yang dinilai.
  final String cleanerId;

  /// 1–5.
  final num penilaian;
  final String komentar;
  final String namaPelanggan;
  final DateTime waktu;

  factory ReviewModel.fromMap(String id, Map<String, dynamic> map) =>
      ReviewModel(
        reviewId: id,
        orderId: map['orderId'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        cleanerId: map['cleanerId'] as String? ?? '',
        penilaian: map['penilaian'] as num? ?? 0,
        komentar: map['komentar'] as String? ?? '',
        namaPelanggan: map['namaPelanggan'] as String? ?? '',
        waktu: (map['waktu'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'reviewId': reviewId,
        'orderId': orderId,
        'userId': userId,
        'cleanerId': cleanerId,
        'penilaian': penilaian,
        'komentar': komentar,
        'namaPelanggan': namaPelanggan,
        'waktu': Timestamp.fromDate(waktu),
      };
}
