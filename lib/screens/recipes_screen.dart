import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:meal_planner/pages/home_screen.dart';
import 'dart:convert';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'calendar_screen.dart';
import 'user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      final fetchedRecipes =
          meals.map<Recipe>((meal) => Recipe.fromJson(meal)).toList();

      if (userId != null) {
        final favSnapshot = await FirebaseFirestore.instance
            .collection('favorites')
            .where('user_id', isEqualTo: userId)
            .get();

        final favIds = favSnapshot.docs.map((doc) => doc['recipe_id']).toSet();

        for (var recipe in fetchedRecipes) {
          recipe.isFavorite = favIds.contains(recipe.id);
        }
      }

      setState(() {
        _recipes = fetchedRecipes;
      });
    } else {
      print('Failed to load recipes');
    }
  }


  void _toggleFavorite(String recipeId) async {
    final index = _recipes.indexWhere((recipe) => recipe.id == recipeId);
    if (index == -1 || userId == null) return;

    final recipe = _recipes[index];
    final favRef = FirebaseFirestore.instance.collection('favorites');

    // Check if it's already in favorites
    final snapshot = await favRef
        .where('user_id', isEqualTo: userId)
        .where('recipe_id', isEqualTo: recipeId)
        .get();

    if (recipe.isFavorite) {
      // 🔴 Remove from favorites
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {
        _recipes[index].isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} removed from Favorites'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (snapshot.docs.isNotEmpty) {
      // 🟡 Already in favorites (shouldn’t happen if logic is synced, but just in case)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} is already in Favorites'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      // 🟢 Add to favorites
      await favRef.add({
        'user_id': userId,
        'recipe_id': recipe.id,
        'recipe_name': recipe.name,
        'image_url': recipe.imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _recipes[index].isFavorite = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} added to Favorites'),
          backgroundColor: const Color.fromARGB(255, 51, 38, 88),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
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
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (newCategory) {
              setState(() {
                _selectedCategory = newCategory!;
              });
            },
            items: [
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
                    builder: (context) => RecipeDetailScreen(
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
              onFavoriteToggle: () => _toggleFavorite(filteredRecipes[index].id),
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
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
