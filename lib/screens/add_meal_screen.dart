import 'package:flutter/material.dart';

class AddMealScreen extends StatelessWidget {
  final TextEditingController mealNameController = TextEditingController();
  final TextEditingController ingredientsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: mealNameController,
              decoration: InputDecoration(labelText: 'Meal Name'),
            ),
            TextField(
              controller: ingredientsController,
              decoration: InputDecoration(labelText: 'Ingredients'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save meal logic
              },
              child: Text('Add Meal'),
            ),
          ],
        ),
      ),
    );
  }
}
