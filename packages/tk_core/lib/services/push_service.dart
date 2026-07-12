import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';

/// Handler pesan FCM saat aplikasi di background/terminated. WAJIB top-level
/// (@pragma vm:entry-point) dan didaftarkan di main sebelum runApp:
///   FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
/// Android menampilkan notifikasi otomatis dari payload `notification`;
/// handler ini cadangan untuk data-only message.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Payload `notification` sudah ditampilkan sistem; tak perlu aksi tambahan.
}

/// Daftarkan [fcmBackgroundHandler] — panggil SEKALI setelah Firebase siap
/// (mis. dari shell setelah login). Dibungkus agar app tak perlu meng-import
/// firebase_messaging langsung.
void registerFcmBackgroundHandler() =>
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

/// Layanan Firebase Cloud Messaging (push tugas ke kru; bisa dipakai app lain).
/// Alur: minta izin → ambil token → simpan via [onToken] → dengar pesan
/// foreground → tampilkan notifikasi lokal (channel bersuara custom).
class PushService {
  PushService({required this.onToken});

  /// Dipanggil dengan token saat pertama didapat & saat refresh — simpan ke
  /// dokumen kru (mis. `FirestoreService.simpanFcmTokenKru`).
  final Future<void> Function(String token) onToken;

  final _fm = FirebaseMessaging.instance;

  /// Inisialisasi setelah pengguna login. Idempoten.
  Future<void> init() async {
    await _fm.requestPermission(alert: true, badge: true, sound: true);
    // iOS: tampilkan notifikasi saat foreground juga.
    await _fm.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    final token = await _fm.getToken();
    if (token != null) await onToken(token);
    _fm.onTokenRefresh.listen(onToken);

    // Pesan saat app di foreground → tampilkan lewat local notification
    // (agar tetap muncul + suara custom; Android tak auto-tampil saat foreground).
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      NotificationService().showLocalNotification(
        n?.title ?? msg.data['judul'] ?? 'Tuntaskilat',
        n?.body ?? msg.data['pesan'] ?? '',
      );
    });
  }

  /// Token perangkat saat ini (untuk dihapus saat logout).
  Future<String?> tokenSekarang() => _fm.getToken();

  /// WAJIB dipanggil saat logout, SETELAH token dihapus dari Firestore:
  /// menginvalidasi token FCM perangkat ini sehingga push untuk akun lama
  /// tidak lagi mendarat di perangkat (bocor lintas akun). Login berikutnya
  /// otomatis mendapat token baru lewat [init]. Dokumen lain yang masih
  /// menyimpan token mati dibersihkan backend saat pengiriman gagal.
  Future<void> hapusTokenPerangkat() => _fm.deleteToken();

  /// Handler pesan saat aplikasi dibuka dari notifikasi (navigasi).
  Stream<RemoteMessage> get onMessageOpened =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Pesan yang MELUNCURKAN app dari keadaan terminated (tap notifikasi saat
  /// app tertutup). Null bila app dibuka normal.
  Future<RemoteMessage?> pesanAwal() => _fm.getInitialMessage();
}

/// Data deep-link dari payload FCM ({orderId, tipe}) — dipakai app untuk
/// menavigasi ke halaman yang tepat saat notifikasi di-tap.
({String orderId, String tipe})? deepLinkDari(RemoteMessage? msg) {
  if (msg == null) return null;
  final orderId = msg.data['orderId']?.toString() ?? '';
  final tipe = msg.data['tipe']?.toString() ?? '';
  if (orderId.isEmpty) return null;
  return (orderId: orderId, tipe: tipe);
}

/// Detail notifikasi lokal bersuara custom Tuntaskilat (dipakai push & lokal).
const tuntaskilatNotifDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'tk_high_importance_channel_v2',
    'Tuntaskilat Notifications',
    channelDescription: 'Notifikasi penting pesanan',
    importance: Importance.max,
    priority: Priority.high,
    // Suara khusus: taruh file di android/app/src/main/res/raw/tuntaskilat_ring.*
    // (mp3/ogg/wav, 1-2 detik). Bila file tak ada, Android pakai default.
    sound: RawResourceAndroidNotificationSound('tuntaskilat_ring'),
    playSound: true,
  ),
);
