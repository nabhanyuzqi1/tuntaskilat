import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService: Menangani background service dan local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi plugin local-notif + buat channel notifikasi (tanpa
  /// menjalankan Foreground Service). Cukup untuk menampilkan push FCM saat
  /// foreground — dipakai Aplikasi Pelanggan yang TIDAK butuh FGS "Online".
  Future<void> ensureChannels() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);
    await _localNotif.initialize(settings: initSettings);

    final androidImplementation = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tk_high_importance_channel_v2',
        'Tuntaskilat Notifications',
        description: 'Notifikasi penting pesanan',
        importance: Importance.max,
        // Suara khusus (file di res/raw/tuntaskilat_ring.*). Channel sound
        // hanya berlaku sejak channel dibuat; hapus data app bila ganti suara.
        sound: RawResourceAndroidNotificationSound('tuntaskilat_ring'),
      ),
    );
  }

  Future<void> initialize() async {
    // 1. Channel notifikasi utama (local-notif + high importance channel).
    await ensureChannels();

    // Channel khusus Foreground Service (Android 12+).
    final androidImplementation = _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tk_background_service',
        'Tuntaskilat Background Service',
        description: 'Background status monitoring service',
        importance: Importance.low,
      ),
    );

    // 2. Konfigurasi Background Service
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        // Android 15+ MELARANG FGS dataSync start dari BOOT_COMPLETED
        // (ForegroundServiceStartNotAllowedException → app crash tiap boot).
        // Service cukup start saat app dibuka (autoStart di atas).
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'tk_background_service',
        initialNotificationTitle: 'Tuntaskilat',
        initialNotificationContent: 'Menunggu pembaruan pesanan...',
        foregroundServiceNotificationId: 888,
        // Android 14+ (targetSDK 34+) WAJIB tipe FGS eksplisit — tanpa ini
        // app crash MissingForegroundServiceTypeException saat startService.
        // dataSync sesuai fungsi service: monitor pembaruan pesanan Firestore.
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    await service.startService();
  }

  void showLocalNotification(String title, String body) {
    _localNotif.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tk_high_importance_channel_v2',
          'Tuntaskilat Notifications',
          channelDescription: 'Notifikasi penting pesanan',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          sound: RawResourceAndroidNotificationSound('tuntaskilat_ring'),
          playSound: true,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final localNotif = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tk_high_importance_channel_v2',
    'Tuntaskilat Notifications',
    description: 'Notifikasi penting pesanan',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('tuntaskilat_ring'),
  );

  const AndroidNotificationChannel bgChannel = AndroidNotificationChannel(
    'tk_background_service',
    'Tuntaskilat Background Service',
    description: 'Background status monitoring service',
    importance: Importance.low,
  );

  final androidImplementation = localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidImplementation?.createNotificationChannel(channel);
  await androidImplementation?.createNotificationChannel(bgChannel);

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  // Pengiriman tugas kini via FCM push (andal walau app ditutup, hemat
  // baterai) — polling Firestore 10 detik DIHAPUS (boros + butuh composite
  // index). Background service ini hanya menjaga notifikasi foreground
  // "Online" agar kru tahu ia siap menerima tugas & proses tak dibunuh OS.
  Timer.periodic(const Duration(minutes: 15), (_) async {
    await prefs.reload();
    final uid = prefs.getString('uid');
    if (service is AndroidServiceInstance && uid != null && uid.isNotEmpty) {
      service.setForegroundNotificationInfo(
        title: 'Tuntaskilat',
        content: 'Anda online — siap menerima tugas.',
      );
    }
  });
}
