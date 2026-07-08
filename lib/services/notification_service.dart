import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {

  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  // ================= INITIALIZE =================

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notifications.initialize(settings);

    // 🔔 Channel WITH carunlock sound
    const soundChannel = AndroidNotificationChannel(
      'health_channel', // keeping your original IDs
      'Vehicle Health Alerts',
      description: 'Health and general notifications',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('carunlock'),
    );

    const serviceChannel = AndroidNotificationChannel(
      'service_channel',
      'Service Notifications',
      description: 'Service booking updates',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('carunlock'),
    );

    const funChannel = AndroidNotificationChannel(
      'fun_channel',
      'Fun Notifications',
      description: 'Playful AutoMind messages',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('carunlock'),
    );

    // 🔕 Theft channel (NO SOUND)
    const theftChannel = AndroidNotificationChannel(
      'theft_channel',
      'Theft Alerts',
      description: 'Silent theft alerts',
      importance: Importance.max,
      playSound: false,
    );

    final androidPlugin =
    _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(soundChannel);
    await androidPlugin?.createNotificationChannel(serviceChannel);
    await androidPlugin?.createNotificationChannel(funChannel);
    await androidPlugin?.createNotificationChannel(theftChannel);
  }

  // ================= HEALTH NOTIFICATION =================

  static Future<void> showHealthNotification(
      String title, String body) async {

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'health_channel',
      'Vehicle Health Alerts',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('carunlock'),
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ================= THEFT ALERT =================

  static Future<void> showTheftNotification(
      String title, String body) async {

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'theft_channel',
      'Theft Alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // 🔕 silent
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      title,
      body,
      details,
    );
  }

  // ================= SERVICE BOOKED =================

  static Future<void> showServiceBookedNotification() async {

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'service_channel',
      'Service Notifications',
      channelDescription: 'Service booking updates',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('carunlock'),
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "🚗 Service Booked!",
      "🛠️ Supervisor will be assigned shortly.",
      details,
    );
  }

  // ================= FUN STARTUP NOTIFICATION =================

  static Future<void> showStartupFunNotification() async {

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'fun_channel',
      'Fun Notifications',
      channelDescription: 'Playful AutoMind messages',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('carunlock'),
      playSound: true,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _notifications.show(
      111, // unique id
      " AutoMind Alert!",
      "Your engine checked itself. It’s judging you.",
      details,
    );
  }
}