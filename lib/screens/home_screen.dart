import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meal Planner')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Breakfast: Oatmeal'),
            subtitle: Text('Ingredients: Oats, Milk, Honey'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/mealDetails',
                arguments: 'Oatmeal',
              );
            },
          ),
          ListTile(
            title: Text('Lunch: Grilled Chicken Salad'),
            subtitle: Text('Ingredients: Chicken, Lettuce, Dressing'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/mealDetails',
                arguments: 'Grilled Chicken Salad',
              );
            },
          ),
          ListTile(
            title: Text('Dinner: Spaghetti Bolognese'),
            subtitle: Text('Ingredients: Spaghetti, Minced Meat, Tomato Sauce'),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/mealDetails',
                arguments: 'Spaghetti Bolognese',
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addMeal');
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
