import 'package:flutter/material.dart';

class MealDetailsScreen extends StatelessWidget {
  final String mealName;
  final String ingredients;

  MealDetailsScreen({required this.mealName, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    // Get the meal name and ingredients from the arguments
    final String mealName =
        ModalRoute.of(context)!.settings.arguments as String;
    final String ingredients = 'Sample Ingredients'; // Replace with actual data

    return Scaffold(
      appBar: AppBar(title: Text(mealName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingredients:', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text(ingredients),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: Text('Edit Meal Plan')),
          ],
        ),
      ),
    );
  }
}
