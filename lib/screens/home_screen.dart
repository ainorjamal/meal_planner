import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Planner'),
        actions: [
          // Add logout button to the app bar
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // Show confirmation dialog
              bool confirm =
                  await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Logout'),
                          content: Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Logout'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                  ) ??
                  false;

              // If confirmed, sign out and navigate to login screen
              if (confirm) {
                await authService.value.signOut();
                // Navigation will be handled by AuthWrapper
              }
            },
          ),
        ],
      ),
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
