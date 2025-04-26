import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
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

    // Request permissions for iOS
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Handle notification tapped
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    // Handle notification tap
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

  // Schedule a meal notification
  Future<void> scheduleMealNotification({
    required int id,
    required String title,
    required String mealName,
    required String mealType,
    required DateTime scheduledDate,
    int reminderMinutes =
        0, // Changed from 30 to 0 for notification at exact time
  }) async {
    // Calculate notification time
    final reminderTime = scheduledDate.subtract(
      Duration(minutes: reminderMinutes),
    );

    // Don't schedule if the time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('Cannot schedule notification in the past: $reminderTime');
      return;
    }

    // Create notification details
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'meal_notifications', // channel id
          'Meal Reminders', // channel name
          channelDescription: 'Notifications for upcoming meals',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          color: Color(0xFF6750A4), // Your purple color
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

    // Format notification message based on meal type
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

      payload: 'meal_$id', // Can be used to navigate to the specific meal
    );

    debugPrint(
      'Scheduled notification for $mealName on ${reminderTime.day}/${reminderTime.month} at ${reminderTime.hour}:${reminderTime.minute}',
    );
  }

  // Create a unique ID based on meal details
  int createUniqueId(String mealId) {
    return mealId.hashCode;
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Schedule notifications for all upcoming meals
  Future<void> scheduleAllMealNotifications(
    List<QueryDocumentSnapshot> mealData,
  ) async {
    // Cancel all existing notifications first
    await cancelAllNotifications();

    for (var doc in mealData) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;

      if (data['date'] != null && data['time'] != null) {
        try {
          // Convert Firestore Timestamp to DateTime
          final DateTime mealDate = (data['date'] as Timestamp).toDate();

          // Parse the time string (assuming format like "7:30 PM")
          final timeString = data['time'] as String;
          final timeParts = timeString.split(' ');
          if (timeParts.length == 2) {
            final hourMinute = timeParts[0].split(':');
            int hour = int.parse(hourMinute[0]);
            final int minute = int.parse(hourMinute[1]);
            final String amPm = timeParts[1].toUpperCase();

            // Convert to 24-hour format
            if (amPm == 'PM' && hour < 12) {
              hour += 12;
            } else if (amPm == 'AM' && hour == 12) {
              hour = 0;
            }

            // Create full DateTime for the meal
            final DateTime scheduledDateTime = DateTime(
              mealDate.year,
              mealDate.month,
              mealDate.day,
              hour,
              minute,
            );

            // Only schedule if the meal is in the future
            if (scheduledDateTime.isAfter(DateTime.now())) {
              await scheduleMealNotification(
                id: createUniqueId(id),
                title: 'Meal Time', // Changed from 'Meal Reminder'
                mealName: data['title'] ?? 'Your Meal',
                mealType: data['mealType'] ?? 'Meal',
                scheduledDate: scheduledDateTime,
                // No reminderMinutes parameter means it will use the default (0)
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
