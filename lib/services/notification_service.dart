/**
 * File: notification_service.dart
 * Deskripsi: Service untuk mengelola notifikasi lokal dengan flutter_local_notifications.
 * Digunakan untuk promosi store dan notifikasi lainnya.
 */
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'dart:async';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Inisialisasi service notifikasi
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inisialisasi timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // Sesuaikan lokasi

    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon'); // Gunakan ikon app

    // iOS settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inisialisasi plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    print('[NotificationService] Initialized successfully');
  }

  /// Handler saat notifikasi di-tap
  void _onNotificationTapped(NotificationResponse response) {
    print('[NotificationService] Notification tapped: ${response.payload}');
    // TODO: Tambahkan navigasi ke halaman terkait jika diperlukan
    // Misalnya jika payload = 'store', navigasi ke StoreScreen
  }

  /// Request permission untuk notifikasi (iOS)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    final bool? result = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return result ?? true; // Android tidak perlu request runtime permission
  }

  /// Kirim notifikasi segera (instant)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'williams_promo_channel', // Channel ID
      'Promosi Williams Store', // Channel name
      channelDescription: 'Notifikasi promosi dan penawaran dari Williams Store',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFF8C8AFA), // Warna aksen ungu
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );

    print('[NotificationService] Instant notification shown: $title');
  }

  /// Kirim notifikasi dengan delay (misalnya 5 detik)
  Future<void> showDelayedNotification({
    required int id,
    required String title,
    required String body,
    required Duration delay,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'williams_promo_channel',
      'Promosi Williams Store',
      channelDescription: 'Notifikasi promosi dan penawaran dari Williams Store',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/launcher_icon',
      color: Color(0xFF8C8AFA),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
     id,
     title,
     body,
     scheduledTime,
     details,
     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
     payload: payload,
   );

    print('[NotificationService] Delayed notification scheduled: $title in ${delay.inSeconds}s');
  }

  /// Kirim notifikasi promosi store dengan delay 5 detik
  Future<void> scheduleStorePromotion() async {
    await showDelayedNotification(
      id: 100, // ID unik untuk notif promo
      title: '🏎️ Promo Williams Store!',
      body: 'Diskon 15% untuk semua merchandise Williams Racing! Tap untuk lihat koleksi.',
      delay: const Duration(seconds: 5),
      payload: 'store', // Payload untuk navigasi
    );
  }

  /// Cancel notifikasi berdasarkan ID
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('[NotificationService] Notification $id cancelled');
  }

  /// Cancel semua notifikasi
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('[NotificationService] All notifications cancelled');
  }

  /// Cek apakah notifikasi pending (scheduled)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}