import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final CollectionReference meals = FirebaseFirestore.instance.collection(
    'meals',
  );
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  // READ
  Stream<QuerySnapshot> getMeals() {
    if (userId == null) throw Exception('User not authenticated');
    return meals
        .where('userId', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // READ SINGLE MEAL
  Future<DocumentSnapshot> getMeal(String mealId) {
    if (userId == null) throw Exception('User not authenticated');
    return meals.doc(mealId).get();
  }

  // CREATE
  Future<void> addMeal({
    required String title,
    required String description,
    required String time,
    String? mealType,
  }) async {
    if (userId == null) throw Exception('User not authenticated');
    await meals.add({
      'title': title,
      'description': description,
      'time': time,
      'mealType': mealType ?? '',
      'userId': userId,
      'logged': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // UPDATE
  Future<void> updateMeal({
    required String mealId,
    required String title,
    required String description,
    required String time,
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
      'logged': logged,
      'userId': userId,
    };

    await meals.doc(mealId).update(data);
  }

  // DELETE
  Future<void> deleteMeal(String mealId) async {
    if (userId == null) throw Exception('User not authenticated');
    await meals.doc(mealId).delete();
  }
}
