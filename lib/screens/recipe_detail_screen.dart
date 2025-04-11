import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  final String userId;

  const RecipeDetailScreen({
    Key? key,
    required this.recipe,
    required this.userId,
  }) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // Function to add the recipe to Firestore favorites
  void _addToFavorites(BuildContext context) {
    FirebaseFirestore.instance.collection('favorites').add({
      'user_id': widget.userId,
      'recipe_id': widget.recipe.id,
      'recipe_name': widget.recipe.name,
      'image_url': widget.recipe.imageUrl,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Favorites')));
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to Favorites')));
    });
  }

  // Function to show the dialog for adding the meal schedule
  void _showAddToMealDialog(BuildContext context) {
    // Function to pick date
    Future<void> _selectDate(BuildContext context) async {
      DateTime initialDate = DateTime.now(); // Set initial date to the current date
      DateTime firstDate = DateTime(2000); // Allow selecting past dates
      DateTime lastDate = DateTime(2100); // Allow selecting dates up to the year 2100

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      if (picked != null && picked != selectedDate)
        setState(() {
          selectedDate = picked;
        });
    }

    // Function to pick time
    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (picked != null && picked != selectedTime)
        setState(() {
          selectedTime = picked;
        });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add to Meal Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date picker button
              Text('Select a date for this meal:'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : '${selectedDate!.toLocal()}'.split(' ')[0], // Display date as string
                ),
              ),
              SizedBox(height: 16),
              // Time picker button
              Text('Select a time for this meal:'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _selectTime(context),
                child: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : '${selectedTime!.format(context)}', // Display time as string
                ),
              ),
              SizedBox(height: 16),
              // Display the selected date and time if picked
              if (selectedDate != null && selectedTime != null) ...[
                Text('Selected Date: ${selectedDate!.toLocal()}'.split(' ')[0]),
                Text('Selected Time: ${selectedTime!.format(context)}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedDate != null && selectedTime != null) {
                  // Combine the selected date and time into a single DateTime object
                  DateTime scheduleDateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  // Add to meals collection in Firestore
                  FirebaseFirestore.instance.collection('meals').add({
                    'user_id': widget.userId,
                    'recipe_id': widget.recipe.id,
                    'schedule': scheduleDateTime,
                  }).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to Meal Plan')));
                    Navigator.of(context).pop(); // Close the dialog
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add to Meal Plan')));
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select both date and time')));
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipe.name)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(widget.recipe.imageUrl),
            SizedBox(height: 16),
            Text('Category: ${widget.recipe.category}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            SizedBox(height: 16),
            Text(widget.recipe.instructions, style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            // Add to Favorites button (Heart Icon)
            IconButton(
              icon: Icon(Icons.favorite_border, color: Colors.red),
              onPressed: () => _addToFavorites(context),
            ),
            // Add to Meal button
            ElevatedButton(
              onPressed: () => _showAddToMealDialog(context),
              child: Text('Add to Meal'),
            ),
          ],
        ),
      ),
    );
  }
}

