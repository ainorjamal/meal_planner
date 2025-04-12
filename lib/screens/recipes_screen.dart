import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_screen.dart';
import 'user_profile_screen.dart';

class RecipesScreen extends StatefulWidget {
  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  String _selectedCategory = 'All';
  String? userId;
  final int _currentIndex = 2; // Set to 2 for Recipes tab
  bool _isDarkMode = false;
  Color primaryColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    // Get the current user ID from Firebase Authentication
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _fetchRecipes() async {
    final response = await http.get(
      Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s='),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final meals = data['meals'] ?? [];

      setState(() {
        _recipes = meals.map<Recipe>((meal) => Recipe.fromJson(meal)).toList();
      });
    } else {
      print('Failed to load recipes');
    }
  }

  void _toggleFavorite(String recipeId) {
    setState(() {
      final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
      if (index != -1) {
        _recipes[index].isFavorite = !_recipes[index].isFavorite;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = Theme.of(context).primaryColor;

    final filteredRecipes =
        _recipes.where((recipe) {
          return _selectedCategory == 'All' ||
              recipe.category == _selectedCategory;
        }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes'),
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (newCategory) {
              setState(() {
                _selectedCategory = newCategory!;
              });
            },
            items:
                [
                  'All',
                  'Vegan',
                  'Vegetarian',
                  'Non-Vegetarian',
                ].map<DropdownMenuItem<String>>((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => RecipeDetailScreen(
                          recipe: filteredRecipes[index],
                          userId: userId!,
                        ),
                  ),
                );
              } else {
                // Handle the case where the userId is null (e.g., user not logged in)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('User not logged in')));
              }
            },
            child: RecipeCard(
              recipe: filteredRecipes[index],
              onFavoriteToggle:
                  () => _toggleFavorite(filteredRecipes[index].id),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor:
            _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            // Home tab
            Navigator.pop(context);
          } else if (index == 1) {
            // Calendar tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CalendarScreen()),
            );
          } else if (index == 2) {
            // Current Recipes tab - do nothing
          } else if (index == 3) {
            // Profile tab
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
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
    );
  }
}
