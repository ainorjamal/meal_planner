import 'package:flutter/material.dart';
import '../models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onFavoriteToggle;

  const RecipeCard({
    required this.recipe,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      elevation: 5,
      child: ListTile(
        leading: Image.network(
          recipe.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(recipe.name), // 🟢 Use 'name' instead of 'title'
        subtitle: Text(recipe.category), // 🟢 Or strInstructions if you add it
        trailing: IconButton(
          icon: Icon(
            recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: recipe.isFavorite ? Colors.red : null,
          ),
          onPressed: onFavoriteToggle,
        ),
      ),
    );
  }
}
