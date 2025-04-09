import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
// Import screens from the screens directory
import '../screens/add_meal_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/meal_details_screen.dart';
import '../screens/recipes_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  Color primaryColor = Colors.green; // Your app's primary color

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meal Planner'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
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

              if (confirm) {
                await authService.value.signOut();
              }
            },
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor:
            _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed, // Added to support 5 items
        onTap: (index) {
          if (index == 1) {
            // Calendar tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );
          } else if (index == 2) {
            // Recipes tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RecipesScreen()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 0
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddMealScreen()),
                  );
                },
                child: Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  // Home tab content
  Widget _buildHomeContent() {
    return ListView(
      children: [
        ListTile(
          title: Text('Breakfast: Oatmeal'),
          subtitle: Text('Ingredients: Oats, Milk, Honey'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        MealDetailsScreen(mealName: 'Oatmeal', ingredients: ''),
              ),
            );
          },
        ),
        ListTile(
          title: Text('Lunch: Grilled Chicken Salad'),
          subtitle: Text('Ingredients: Chicken, Lettuce, Dressing'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MealDetailsScreen(
                      mealName: 'Grilled Chicken Salad',
                      ingredients: '',
                    ),
              ),
            );
          },
        ),
        ListTile(
          title: Text('Dinner: Spaghetti Bolognese'),
          subtitle: Text('Ingredients: Spaghetti, Minced Meat, Tomato Sauce'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MealDetailsScreen(
                      mealName: 'Spaghetti Bolognese',
                      ingredients: '',
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Grocery tab content

  // Profile tab content
  Widget _buildProfileContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'User Name',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('user@example.com', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text('Favorite Recipes'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Meal History'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
