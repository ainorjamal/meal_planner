import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirestoreService {
  final CollectionReference meals = FirebaseFirestore.instance.collection(
    'meals',
  );
  final CollectionReference mealHistory = FirebaseFirestore.instance.collection(
    'meal_history',
  );
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  final NotificationService _notificationService = NotificationService();

  // READ
  Stream<QuerySnapshot> getMeals() {
    if (userId == null) throw Exception('User not authenticated');
    return meals
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
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

  // Move meal to history (for past meals or user-initiated moves)
  Future<void> moveMealToHistory(
    String mealId, {
    String reason = 'manual',
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    try {
      final mealDoc = await meals.doc(mealId).get();
      if (!mealDoc.exists) {
        debugPrint('Meal $mealId does not exist');
        return;
      }

      final mealData = mealDoc.data() as Map<String, dynamic>;

      // Add metadata for when meal is moved to history and why
      final updatedMealData = {
        ...mealData,
        'movedAt': Timestamp.now(),
        'moveReason': reason, // 'auto', 'manual', 'expired', etc.
      };

      // Save to meal_history collection with the same document ID
      await mealHistory.doc(mealId).set(updatedMealData);

      // Delete from original meals collection
      await meals.doc(mealId).delete();

      // Cancel notifications
      await _notificationService.cancelNotification(
        _notificationService.createUniqueId(mealId),
      );

      debugPrint('Moved meal $mealId to history (reason: $reason)');
    } catch (e) {
      debugPrint('Error moving meal $mealId to history: $e');
      rethrow;
    }
  }

  // Permanently delete meal (use sparingly - mainly for cleanup)
  Future<void> permanentlyDeleteMeal(String mealId) async {
    if (userId == null) throw Exception('User not authenticated');

    try {
      // Cancel notification before deleting the meal
      await _notificationService.cancelNotification(
        _notificationService.createUniqueId(mealId),
      );

      // Delete from meals collection
      await meals.doc(mealId).delete();

      // Also delete from history if it exists there
      await mealHistory.doc(mealId).delete();

      debugPrint('Permanently deleted meal $mealId');
    } catch (e) {
      debugPrint('Error permanently deleting meal $mealId: $e');
      rethrow;
    }
  }

  // DELETE - Now moves to history instead of permanent deletion
  Future<void> deleteMeal(String mealId) async {
    // By default, "deleting" a meal moves it to history
    await moveMealToHistory(mealId, reason: 'user_deleted');
  }

  // Restore meal from history back to active meals
  Future<void> restoreMealFromHistory(String mealId) async {
    if (userId == null) throw Exception('User not authenticated');

    try {
      final historyDoc = await mealHistory.doc(mealId).get();
      if (!historyDoc.exists) {
        debugPrint('Meal $mealId does not exist in history');
        return;
      }

      final mealData = historyDoc.data() as Map<String, dynamic>;

      // Remove history metadata
      mealData.remove('movedAt');
      mealData.remove('moveReason');

      // Update the date to future if it's in the past
      if (mealData['date'] != null && mealData['date'] is Timestamp) {
        final mealDate = (mealData['date'] as Timestamp).toDate();
        final now = DateTime.now();
        if (mealDate.isBefore(now)) {
          // Move the meal to tomorrow at the same time
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          mealData['date'] = Timestamp.fromDate(
            DateTime(
              tomorrow.year,
              tomorrow.month,
              tomorrow.day,
              mealDate.hour,
              mealDate.minute,
            ),
          );
        }
      }

      // Add back to meals collection
      await meals.doc(mealId).set(mealData);

      // Remove from history
      await mealHistory.doc(mealId).delete();

      // Reschedule notification if the meal is in the future
      if (mealData['mealType'] != null &&
          mealData['title'] != null &&
          mealData['time'] != null &&
          mealData['date'] != null) {
        await _scheduleNotificationForMeal(
          mealId: mealId,
          title: mealData['title'],
          time: mealData['time'],
          date: (mealData['date'] as Timestamp).toDate(),
          mealType: mealData['mealType'],
        );
      }

      debugPrint('Restored meal $mealId from history');
    } catch (e) {
      debugPrint('Error restoring meal $mealId from history: $e');
      rethrow;
    }
  }

  // Get meal history for the user
  Stream<QuerySnapshot> getMealHistory() {
    if (userId == null) throw Exception('User not authenticated');
    return mealHistory
        .where('userId', isEqualTo: userId)
        .orderBy('movedAt', descending: true)
        .snapshots();
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

  Future<List<DocumentSnapshot>> fetchCombinedMeals() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final mealsSnapshot =
        await FirebaseFirestore.instance
            .collection('meals')
            .where('userId', isEqualTo: userId)
            .get();

    return mealsSnapshot.docs;
  }

  // Auto-move past meals to history (called periodically)
  Future<void> autoMovePastMealsToHistory() async {
    if (userId == null) throw Exception('User not authenticated');

    try {
      final now = DateTime.now();
      final QuerySnapshot pastMealsSnapshot =
          await meals
              .where('userId', isEqualTo: userId)
              .where(
                'date',
                isLessThan: Timestamp.fromDate(
                  DateTime(now.year, now.month, now.day),
                ),
              )
              .get();

      for (var doc in pastMealsSnapshot.docs) {
        await moveMealToHistory(doc.id, reason: 'auto_expired');
      }

      if (pastMealsSnapshot.docs.isNotEmpty) {
        debugPrint(
          'Auto-moved ${pastMealsSnapshot.docs.length} past meals to history',
        );
      }
    } catch (e) {
      debugPrint('Error auto-moving past meals to history: $e');
    }
  }
}
