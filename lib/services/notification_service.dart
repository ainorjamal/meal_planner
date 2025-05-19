import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';  // Added import

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  // New method to request notification permission on Android 13+
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint('Notification permission granted');
      } else {
        debugPrint('Notification permission denied');
      }
    } else {
      debugPrint('Notification permission already granted');
    }
  }

  Future<void> initialize() async {
    // Request notification permission on Android 13+
    await _requestNotificationPermission();

    // Initialize timezone database
    tz_init.initializeTimeZones();

    // Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: onDidReceiveLocalNotification,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Request permissions for iOS (still keep this)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Handle notification tapped
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      debugPrint('Notification payload: ${response.payload}');
      // Navigate to specific meal or calendar page based on payload
    }
  }

  // For iOS < 10
  Future onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Display a dialog with the notification details
  }

  Future<void> scheduleMealNotification({
    required int id,
    required String title,
    required String mealName,
    required String mealType,
    required DateTime scheduledDate,
    int reminderMinutes = 0,
  }) async {
    final reminderTime = scheduledDate.subtract(
      Duration(minutes: reminderMinutes),
    );

    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule notification in the past: $reminderTime');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'meal_notifications',
      'Meal Reminders',
      channelDescription: 'Notifications for upcoming meals',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      color: Color(0xFF6750A4),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    String body = 'Time for your $mealType: $mealName';

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'meal_$id',
    );

    debugPrint(
      'Scheduled notification for $mealName on ${reminderTime.day}/${reminderTime.month} at ${reminderTime.hour}:${reminderTime.minute}',
    );
  }

  int createUniqueId(String mealId) {
    return mealId.hashCode;
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> scheduleAllMealNotifications(
    List<QueryDocumentSnapshot> mealData,
  ) async {
    await cancelAllNotifications();

    for (var doc in mealData) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;

      if (data['date'] != null && data['time'] != null) {
        try {
          final DateTime mealDate = (data['date'] as Timestamp).toDate();

          final timeString = data['time'] as String;
          final timeParts = timeString.split(' ');
          if (timeParts.length == 2) {
            final hourMinute = timeParts[0].split(':');
            int hour = int.parse(hourMinute[0]);
            final int minute = int.parse(hourMinute[1]);
            final String amPm = timeParts[1].toUpperCase();

            if (amPm == 'PM' && hour < 12) {
              hour += 12;
            } else if (amPm == 'AM' && hour == 12) {
              hour = 0;
            }

            final DateTime scheduledDateTime = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
              hour,
              minute,
            );

            if (scheduledDateTime.isAfter(DateTime.now())) {
              await scheduleMealNotification(
                id: createUniqueId(id),
                title: 'Meal Time',
                mealName: data['title'] ?? 'Your Meal',
                mealType: data['mealType'] ?? 'Meal',
                scheduledDate: scheduledDateTime,
              );
            }
          }
        } catch (e) {
          debugPrint('Error scheduling notification for meal $id: $e');
        }
      }
    }
  }
}
