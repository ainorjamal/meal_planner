import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '/screens/recipe_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  Future<Recipe?> fetchRecipe(String recipeId) async {
    final url = 'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$recipeId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['meals'] != null && data['meals'].length > 0) {
        final meal = data['meals'][0];
        return Recipe(
          id: meal['idMeal'],
          name: meal['strMeal'],
          category: meal['strCategory'],
          imageUrl: meal['strMealThumb'],
          instructions: meal['strInstructions'],
        );
      }
    }

    return null;
  }

  void _deleteFavorite(String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('favorites').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting favorite: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Favorite Recipes')),
        body: Center(child: Text('You need to be logged in to view your favorites.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Favorite Recipes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('user_id', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No favorite recipes added.'));
          }

          final favoriteDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: favoriteDocs.length,
            itemBuilder: (context, index) {
              final favorite = favoriteDocs[index];
              final recipeId = favorite['recipe_id'];
              final docId = favorite.id;

              return FutureBuilder<Recipe?>(
                future: fetchRecipe(recipeId),
                builder: (context, recipeSnapshot) {
                  if (recipeSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading...'),
                      leading: CircularProgressIndicator(),
                    );
                  }

                  if (!recipeSnapshot.hasData || recipeSnapshot.data == null) {
                    return ListTile(
                      title: Text('Recipe not found'),
                      subtitle: Text('ID: $recipeId'),
                    );
                  }

                  final recipe = recipeSnapshot.data!;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      leading: Image.network(recipe.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(recipe.name),
                      subtitle: Text('Category: ${recipe.category}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: recipe, userId: currentUser.uid),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFavorite(docId, context),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
