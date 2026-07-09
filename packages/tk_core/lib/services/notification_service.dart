import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

/// NotificationService: Menangani background service dan local notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Inisialisasi local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _localNotif.initialize(settings: initSettings);

    // Create notification channels (essential for Android 12+ foreground services)
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

    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tk_high_importance_channel',
        'Tuntaskilat Notifications',
        description: 'Notifikasi penting pesanan',
        importance: Importance.max,
      ),
    );

    // 2. Konfigurasi Background Service
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        autoStartOnBoot: true,
        isForegroundMode: true,
        notificationChannelId: 'tk_background_service',
        initialNotificationTitle: 'Tuntaskilat',
        initialNotificationContent: 'Menunggu pembaruan pesanan...',
        foregroundServiceNotificationId: 888,
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
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tk_high_importance_channel',
          'Tuntaskilat Notifications',
          channelDescription: 'Notifikasi penting pesanan',
          importance: Importance.max,
          priority: Priority.high,
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
    'tk_high_importance_channel',
    'Tuntaskilat Notifications',
    description: 'Notifikasi penting pesanan',
    importance: Importance.max,
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

  String? lastNotifId;

  // Dengarkan notifikasi dari Firestore secara terus-menerus
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    // Kita harus ambil UID yang aktif dari shared preferences karena di isolate berbeda
    // auth state mungkin tidak sinkron atau butuh re-init. SharedPreferences aman lintas isolate.
    await prefs.reload();
    final uid = prefs.getString('uid');
    if (uid == null || uid.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('dibaca', isEqualTo: false)
        .orderBy('waktu', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      if (doc.id != lastNotifId) {
        lastNotifId = doc.id;
        final notif = NotificationModel.fromMap(doc.id, doc.data());
        
        localNotif.show(
          id: notif.notificationId.hashCode,
          title: notif.judul,
          body: notif.pesan,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    }
  });
}
