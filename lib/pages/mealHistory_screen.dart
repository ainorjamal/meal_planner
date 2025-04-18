import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MealHistoryScreen extends StatefulWidget {
  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  @override
  void initState() {
    super.initState();
    _checkMealsForHistory(); // Check meals when the screen is loaded
  }

  // Function to check meals and move expired ones to history
  void _checkMealsForHistory() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance.collection('meals').get();

    for (final doc in snapshot.docs) {
      final data = doc.data();

      // Get user_id (can be either 'user_id' or 'userId')
      final mealUserId = data['user_id'] ?? data['userId'];
      if (mealUserId != currentUser.uid) {
        print('Skipping ${doc.id} - not user\'s meal.');
        continue;
      }

      // Ensure the 'date' field exists and is a Timestamp
      if (data['date'] == null || data['date'] is! Timestamp) {
        print('Skipping ${doc.id} - invalid or missing date.');
        continue;
      }

      final mealDate = (data['date'] as Timestamp).toDate();
      final currentDate = DateTime.now();

      // If date is in the future, skip
      if (!mealDate.isBefore(currentDate)) {
        print('Skipping ${doc.id} - date is not in the past.');
        continue;
      }

      // Ready to move this meal
      final mealName = data['meal_name'] ??
          data['recipe_name'] ??
          data['mealName'] ??
          data['title'] ??
          'Unnamed Meal';

      final category = data['category'] ?? data['mealType'] ?? 'Uncategorized';

      print('Moving meal ${doc.id} to history');
      _moveMealToHistory(doc.id, mealName, category, mealDate, mealUserId);
    }
  } catch (e) {
    print('Error checking meals: $e');
  }
}

  // Function to move a meal to the meal_history collection and delete from meals
  void _moveMealToHistory(String mealId, String mealName, String category, DateTime mealDate, String userId) {
    FirebaseFirestore.instance.collection('meal_history').add({
      'meal_name': mealName,
      'category': category,
      'date': mealDate.toIso8601String(),
      'user_id': userId, // Store user_id in history
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      // After adding to meal history, delete the meal from the active meals collection
      FirebaseFirestore.instance.collection('meals').doc(mealId).delete().then((_) {
        print('Meal moved to history and removed from meals');
      }).catchError((error) {
        print('Error removing meal from meals collection: $error');
      });
    }).catchError((error) {
      print('Error moving meal to history: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal History'),
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMealHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final mealHistory = snapshot.data ?? [];
          return mealHistory.isEmpty
              ? Center(child: Text('No meal history available.'))
              : ListView.builder(
                  itemCount: mealHistory.length,
                  itemBuilder: (context, index) {
                    final meal = mealHistory[index];
                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 5,
                      child: ListTile(
                        leading: Icon(Icons.restaurant_menu),
                        title: Text(meal['mealName']),
                        subtitle: Text('Category: ${meal['category']}, Date: ${meal['date']}'),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Show the meal details in a dialog
                          _showMealDetailsDialog(
                            context,
                            meal['mealName'],
                            meal['category'],
                            meal['date']
                          );
                        },
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  // Function to fetch meal history from Firestore
  Future<List<Map<String, dynamic>>> _fetchMealHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID

      if (userId == null) {
        print('No user is logged in');
        return []; // Return empty if no user is logged in
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('meal_history')
          .where('user_id', isEqualTo: userId) // Filter by user_id
          .get();

      final result = snapshot.docs.map((doc) {
        final data = doc.data();

        // Handle both 'user_id' and 'userId'
        final currentUserId = data['user_id'] ?? data['userId'] ?? 'Unknown user';  // Check both 'user_id' and 'userId'

        final mealName = data.containsKey('meal_name') && data['meal_name'].toString().isNotEmpty
            ? data['meal_name']
            : data.containsKey('recipe_name') && data['recipe_name'].toString().isNotEmpty
                ? data['recipe_name']
                : data.containsKey('mealName') && data['mealName'].toString().isNotEmpty
                    ? data['mealName']
                    : data.containsKey('title') && data['title'].toString().isNotEmpty
                        ? data['title']
                        : 'Unknown meal';

        final rawDate = data['date'];
        String formattedDate;

        if (rawDate is Timestamp) {
          formattedDate = DateFormat.yMMMMd().format(rawDate.toDate());
        } else if (rawDate is String) {
          try {
            final parsed = DateTime.parse(rawDate);
            formattedDate = DateFormat.yMMMMd().format(parsed);
          } catch (e) {
            formattedDate = 'Invalid date';
          }
        } else {
          formattedDate = 'Unknown date';
        }

        // Check both 'category' and 'mealType' fields for category
        final category = data['category'] ?? data['mealType'] ?? 'Unknown category';

        return {
          'mealName': mealName,
          'date': formattedDate,
          'category': category,
        };
      }).toList();

      return result;
    } catch (e) {
      print('Error fetching meals for user: $e');
      return [];
    }
  }

  // Function to show meal details in a dialog
  void _showMealDetailsDialog(BuildContext context, String mealName, String category, String date) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Meal Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Meal Name: $mealName', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('Category: $category', style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text('Date: $date', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
