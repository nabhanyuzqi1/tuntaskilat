import 'package:cloud_firestore/cloud_firestore.dart';

/// Koleksi `notifications` — lihat firestore-schema.md.
class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.judul,
    required this.pesan,
    required this.waktu,
    required this.dibaca,
    this.orderId,
  });

  final String notificationId;

  /// Penerima.
  final String userId;
  final String judul;
  final String pesan;
  final DateTime waktu;
  final bool dibaca;

  /// Opsional — untuk deep link ke pesanan.
  final String? orderId;

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      NotificationModel(
        notificationId: id,
        userId: map['userId'] as String? ?? '',
        judul: map['judul'] as String? ?? '',
        pesan: map['pesan'] as String? ?? '',
        waktu: (map['waktu'] as Timestamp).toDate(),
        dibaca: map['dibaca'] as bool? ?? false,
        orderId: map['orderId'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'notificationId': notificationId,
        'userId': userId,
        'judul': judul,
        'pesan': pesan,
        'waktu': Timestamp.fromDate(waktu),
        'dibaca': dibaca,
        'orderId': orderId,
      };
}
