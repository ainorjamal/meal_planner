import 'package:flutter/material.dart';

class MealDetailsScreen extends StatelessWidget {
  final String mealId;
  final String mealName;
  final String ingredients;

  MealDetailsScreen({
    required this.mealId,
    required this.mealName,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meal Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(ingredients),
            SizedBox(height: 16),
            Text(
              'Meal ID: $mealId', // Display the meal ID (for debugging/reference)
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            // You can add more details here based on the mealId
          ],
        ),
      ),
    );
  }
}
