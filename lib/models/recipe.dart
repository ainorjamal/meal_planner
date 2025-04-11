// lib/models/recipe.dart

class Recipe {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String instructions;
  bool isFavorite; // <-- Add this

  Recipe({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.instructions,
    this.isFavorite = false, // <-- Initialize it
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['idMeal'] ?? '',
      name: json['strMeal'] ?? '',
      imageUrl: json['strMealThumb'] ?? '',
      category: json['strCategory'] ?? '',
      instructions: json['strInstructions'] ?? '',
    );
  }
}
