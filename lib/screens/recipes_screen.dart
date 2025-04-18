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

// Custom color palette for the app
class AppColors {
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryPurple = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color surface = Color(0xFFF3EEFF);
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF158544);
  
  // Dark mode colors
  static const Color darkSurface = Color(0xFF1C1B1F);
  static const Color darkBackground = Color(0xFF121212);
}

class RecipesScreen extends StatefulWidget {
  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  List<Recipe> _recipes = [];
  String _selectedCategory = 'All';
  String? userId;
  final int _currentIndex = 2; // Set to 2 for Recipes tab
  bool _isDarkMode = false;
  bool _isLoading = true;
  List<String> _categories = [
    'All',
    'Miscellaneous',
    'Seafood',
    'Side',
    'Vegetarian',
    'Beef',
    'Pork',
    'Pasta',
    'Dessert',
    'Lamb',
    'Chicken',
  ];
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fetchRecipes();
    // Get the current user ID from Firebase Authentication
    userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
    });
    
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
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
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
      // Remove from favorites
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      setState(() {
        _recipes[index].isFavorite = false;
      });
      _showSnackBar(
        '${recipe.name} removed from Favorites',
        AppColors.error,
        Icons.favorite_border,
      );
    } else if (snapshot.docs.isNotEmpty) {
      // Already in favorites (shouldn't happen if logic is synced, but just in case)
      _showSnackBar(
        '${recipe.name} is already in Favorites',
        Colors.orange,
        Icons.favorite,
      );
    } else {
      // Add to favorites
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

      _showSnackBar(
        '${recipe.name} added to Favorites',
        AppColors.success,
        Icons.favorite,
      );
    }
  }

  void _showSnackBar(String message, Color backgroundColor, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: Duration(seconds: 2),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter recipes based on selected category
    final filteredRecipes = _recipes.where((recipe) {
      return _selectedCategory == 'All' ||
          recipe.category == _selectedCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recipes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: _isDarkMode ? AppColors.darkPurple : AppColors.primaryPurple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category selector
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? AppColors.darkSurface : AppColors.lightPurple,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : _isDarkMode
                                ? Colors.white70
                                : AppColors.darkPurple,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
                    selectedColor: AppColors.secondaryPurple,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              },
            ),
          ),
          
          // Recipe list or loading indicator
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                    ),
                  )
                : filteredRecipes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.no_food_outlined,
                              size: 64,
                              color: _isDarkMode ? Colors.grey : Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No recipes found',
                              style: TextStyle(
                                fontSize: 18,
                                color: _isDarkMode ? Colors.grey : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchRecipes,
                        color: AppColors.primaryPurple,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          itemCount: filteredRecipes.length,
                          itemBuilder: (context, index) {
                            final recipe = filteredRecipes[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: _buildRecipeCard(recipe),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        backgroundColor: _isDarkMode ? AppColors.darkBackground : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
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
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.food_bank_outlined),
            activeIcon: Icon(Icons.food_bank),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement search functionality
          showSearch(
            context: context,
            delegate: RecipeSearchDelegate(_recipes, userId, _toggleFavorite),
          );
        },
        backgroundColor: AppColors.secondaryPurple,
        child: Icon(Icons.search, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        if (userId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailScreen(
                recipe: recipe,
                userId: userId!,
              ),
            ),
          );
        } else {
          _showSnackBar(
            'User not logged in',
            Colors.red,
            Icons.error_outline,
          );
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image with favorite button overlay
            Stack(
              children: [
                // Recipe image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Category label
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.darkPurple.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      recipe.category,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleFavorite(recipe.id),
                      customBorder: CircleBorder(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: recipe.isFavorite ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Recipe info
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.public,
                        size: 16,
                        color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        recipe.category, // Using category instead of area
                        style: TextStyle(
                          color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '30 min', // Placeholder, replace with actual time if available
                        style: TextStyle(
                          color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search functionality
class RecipeSearchDelegate extends SearchDelegate<String> {
  final List<Recipe> recipes;
  final String? userId;
  final Function(String) onFavoriteToggle;

  RecipeSearchDelegate(this.recipes, this.userId, this.onFavoriteToggle);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      primaryColor: isDark ? AppColors.darkPurple : AppColors.primaryPurple,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkPurple : AppColors.primaryPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle( // Updated from headline6 to titleLarge
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildSearchResults(context);
  }

  Widget buildSearchResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter recipes based on query
    final results = query.isEmpty
        ? []
        : recipes
            .where((recipe) =>
                recipe.name.toLowerCase().contains(query.toLowerCase()) ||
                recipe.category.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              query.isEmpty ? Icons.search : Icons.no_food,
              size: 64,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Search for recipes'
                  : 'No recipes found for "$query"',
              style: TextStyle(
                fontSize: 18,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final recipe = results[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: InkWell(
            onTap: () {
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailScreen(
                      recipe: recipe,
                      userId: userId!,
                    ),
                  ),
                );
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Recipe image
                Container(
                  width: 100,
                  height: 100,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),
                ),
                
                // Recipe details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 14,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                            SizedBox(width: 4),
                            Text(
                              recipe.category,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Favorite button
                Padding(
                  padding: EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(
                      recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: recipe.isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => onFavoriteToggle(recipe.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}