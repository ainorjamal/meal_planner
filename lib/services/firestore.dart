import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';

class FirestoreService {
  final CollectionReference meals = FirebaseFirestore.instance.collection(
    'meals',
  );
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final NotificationService _notificationService = NotificationService();

  // READ
  Stream<QuerySnapshot> getMeals() {
    if (userId == null) throw Exception('User not authenticated');
    return meals
        .where('userId', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  Future<void> scheduleNotificationsForAllUserMeals() async {
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Get all future meals for the current user
      final QuerySnapshot mealSnapshot =
          await meals
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
              )
              .get();

      // Cancel all existing notifications first to avoid duplicates
      await _notificationService.cancelAllNotifications();

      // Schedule notifications for all retrieved meals
      for (var doc in mealSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final mealId = doc.id;

        try {
          if (data['date'] != null &&
              data['time'] != null &&
              data['title'] != null &&
              data['mealType'] != null) {
            await _scheduleNotificationForMeal(
              mealId: mealId,
              title: data['title'],
              time: data['time'],
              date: (data['date'] as Timestamp).toDate(),
              mealType: data['mealType'],
            );
          }
        } catch (e) {
          debugPrint('Error scheduling notification for meal $mealId: $e');
        }
      }

      debugPrint(
        'Scheduled notifications for ${mealSnapshot.docs.length} upcoming meals',
      );
    } catch (e) {
      debugPrint('Error scheduling notifications for all meals: $e');
    }
  }

  // READ SINGLE MEAL
  Future<DocumentSnapshot> getMeal(String mealId) {
    if (userId == null) throw Exception('User not authenticated');
    return meals.doc(mealId).get();
  }

  // CREATE with automatic notification scheduling
  Future<DocumentReference> addMeal({
    required String title,
    required String description,
    required String time,
    required DateTime date,
    required String mealType,
  }) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final mealData = {
      'title': title,
      'description': description,
      'time': time,
      'date': date,
      'mealType': mealType,
      'userId': userId,
      'logged': false,
      'createdAt': Timestamp.now(),
    };

    // Add the meal and get the DocumentReference
    final DocumentReference docRef = await FirebaseFirestore.instance
        .collection('meals')
        .add(mealData);

    // Schedule notification for this meal
    await _scheduleNotificationForMeal(
      mealId: docRef.id,
      title: title,
      time: time,
      date: date,
      mealType: mealType,
    );

    return docRef;
  }

  // Helper method to schedule a notification for a meal
  Future<void> _scheduleNotificationForMeal({
    required String mealId,
    required String title,
    required String time,
    required DateTime date,
    required String mealType,
  }) async {
    try {
      // Parse the time string (assuming format like "7:30 PM")
      final timeParts = time.split(' ');
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
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        // Schedule notification
        await _notificationService.scheduleMealNotification(
          id: _notificationService.createUniqueId(mealId),
          title: 'Meal Reminder',
          mealName: title,
          mealType: mealType,
          scheduledDate: scheduledDateTime,
        );

        debugPrint(
          'Scheduled notification for meal: $title at ${scheduledDateTime.toString()}',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notification for meal $mealId: $e');
    }
  }

  // UPDATE
  Future<void> updateMeal({
    required String mealId,
    required String title,
    required String description,
    required String time,
    required DateTime date,
    required bool logged,
    String? mealType,
    int? satisfaction,
    String? mood,
    String? notes,
  }) async {
    if (userId == null) throw Exception('User not authenticated');
    Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'time': time,
      'date': date,
      'logged': logged,
      'userId': userId,
    };

    // Include optional fields if they're provided
    if (mealType != null) data['mealType'] = mealType;
    if (satisfaction != null) data['satisfaction'] = satisfaction;
    if (mood != null) data['mood'] = mood;
    if (notes != null) data['notes'] = notes;

    await meals.doc(mealId).update(data);

    // Cancel existing notification and reschedule
    if (mealType != null) {
      await _notificationService.cancelNotification(
        _notificationService.createUniqueId(mealId),
      );
      await _scheduleNotificationForMeal(
        mealId: mealId,
        title: title,
        time: time,
        date: date,
        mealType: mealType,
      );
    }
  }

  // DELETE
  Future<void> deleteMeal(String mealId) async {
    if (userId == null) throw Exception('User not authenticated');

    // Cancel notification before deleting the meal
    await _notificationService.cancelNotification(
      _notificationService.createUniqueId(mealId),
    );

    await meals.doc(mealId).delete();
  }

  Future<List<DocumentSnapshot>> fetchCombinedMeals() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return [];

  final meals1 = await FirebaseFirestore.instance
      .collection('meals')
      .where('user_id', isEqualTo: userId)
      .get();

  final meals2 = await FirebaseFirestore.instance
      .collection('meals')
      .where('userId', isEqualTo: userId)
      .get();

  return [...meals1.docs, ...meals2.docs];
}
}
