import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart'; // <-- Make sure this import exists
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import Firebase Auth

class RecipesScreen extends StatefulWidget {
  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<Recipe> _recipes = [];
  String _selectedCategory = 'All';
  String? userId;

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
    final filteredRecipes = _recipes.where((recipe) {
      return _selectedCategory == 'All' || recipe.category == _selectedCategory;
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
            items: ['All', 'Vegan', 'Vegetarian', 'Non-Vegetarian']
                .map<DropdownMenuItem<String>>((category) {
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
                      userId: userId!, // <-- Pass userId here
                    ),
                  ),
                );
              } else {
                // Handle the case where the userId is null (e.g., user not logged in)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('User not logged in'),
                ));
              }
            },
            child: RecipeCard(
              recipe: filteredRecipes[index],
              onFavoriteToggle: () => _toggleFavorite(filteredRecipes[index].id),
            ),
          );
        },
      ),
    );
  }
}
