import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '/screens/recipe_detail_screen.dart';

class AppColors {
  static Color primaryPurple(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFFB39DDB) : Color(0xFF6A4AA1);

  static Color secondaryPurple(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFFD1C4E9) : Color(0xFF8B70C4);

  static Color lightPurple(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFF2C2C34) : Color(0xFFE7E1F7);

  static Color darkPurple(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFFEDE7F6) : Color(0xFF4D2C91);

  static Color white(Brightness brightness) =>
      brightness == Brightness.dark ? Colors.black : Colors.white;

  static Color grey(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFF121212) : Color(0xFFF8F8F8);

  static Color darkGrey(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFFCCCCCC) : Color(0xFF555555);

  static const Color deleteRed = Color(0xFFE53935);

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? Color(0xFF1E1E1E) : Color(0xFFFCFBFF);

  static const Color accentYellow = Color(0xFFFFD54F);

  static Color shadowColor(Brightness brightness) =>
      darkPurple(brightness).withOpacity(0.08);

  static List<Color> primaryGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? [Color(0xFF9575CD), Color(0xFFB39DDB)]
          : [Color(0xFF5E35B1), Color(0xFF7E57C2)];

  static List<Color> backgroundGradient(Brightness brightness) =>
      brightness == Brightness.dark
          ? [Color(0xFF2C2C34), Color(0xFF1E1E1E)]
          : [lightPurple(brightness), white(brightness)];
}

class FavoritesScreen extends StatelessWidget {
  static final BorderRadius cardBorderRadius = BorderRadius.circular(18);
  static const double contentPadding = 16.0;
  static const double cardElevation = 4.0;
  static const double imageSize = 86.0;

  Future<Recipe?> fetchRecipe(String recipeId) async {
    final url =
        'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$recipeId';
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

  void _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String recipeName,
  ) {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          backgroundColor: AppColors.white(brightness),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.deleteRed.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deleteRed.withOpacity(0.12),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.deleteRed,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Remove Favorite',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkPurple(brightness),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to remove "$recipeName" from your favorites?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.darkGrey(brightness),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkGrey(brightness),
                          side: BorderSide(
                            color: AppColors.darkGrey(
                              brightness,
                            ).withOpacity(0.3),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deleteRed,
                          foregroundColor: AppColors.white(brightness),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shadowColor: AppColors.deleteRed.withOpacity(0.4),
                        ),
                        child: Text(
                          'Remove',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteFavorite(docId, context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteFavorite(String docId, BuildContext context) async {
    final brightness = Theme.of(context).brightness;

    try {
      await FirebaseFirestore.instance
          .collection('favorites')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.white(brightness),
              ),
              SizedBox(width: 12),
              Text(
                'Removed from favorites',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.darkPurple(brightness),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
          elevation: 4,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.white(brightness),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error deleting favorite: $e',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.deleteRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
          elevation: 4,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        title: Text(
          'Favorite Recipes',
          style: TextStyle(
            color: AppColors.white(brightness),
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryPurple(brightness),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.white(brightness),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(color: AppColors.white(brightness)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.favorite_rounded,
              size: 22,
              color: AppColors.white(brightness),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightPurple(brightness).withOpacity(0.5),
              AppColors.white(brightness),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child:
            currentUser == null
                ? _buildLoginRequired(context)
                : _buildFavoritesList(context, currentUser),
      ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.lightPurple(brightness).withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple(brightness).withOpacity(0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 70,
                color: AppColors.primaryPurple(brightness),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple(brightness),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'You need to be logged in to view your favorites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.darkGrey(brightness),
                height: 1.4,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.login_rounded, size: 20),
              label: Text(
                'Log In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // Navigate to login screen
                // Add your navigation logic here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple(brightness),
                foregroundColor: AppColors.white(brightness),
                padding: EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: AppColors.primaryPurple(
                  brightness,
                ).withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(BuildContext context, User currentUser) {
    final brightness = Theme.of(context).brightness;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('favorites')
              .where('user_id', isEqualTo: currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        if (snapshot.hasError) {
          return _buildErrorState(context, snapshot.error);
        }

        int totalFavorites = 0;
        if (snapshot.hasData) {
          totalFavorites = snapshot.data!.docs.length;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple(brightness),
                      AppColors.secondaryPurple(brightness),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkPurple(brightness).withOpacity(0.3),
                      offset: Offset(0, 8),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Favorite Recipes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'You have $totalFavorites recipes in your favorites',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Show empty or list state based on data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              Expanded(child: _buildEmptyState(context))
            else
              Expanded(
                child: _buildFavoritesListView(
                  context,
                  snapshot.data!.docs,
                  currentUser,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryPurple(brightness),
            ),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Loading favorites...',
            style: TextStyle(
              color: AppColors.darkPurple(brightness),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object? error) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.deleteRed.withOpacity(0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deleteRed.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 65,
                color: AppColors.deleteRed,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Error Loading Favorites',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple(brightness),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkGrey(brightness),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.lightPurple(brightness).withOpacity(0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple(
                      brightness,
                    ).withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 70,
                color: AppColors.primaryPurple(brightness),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'No Favorite Recipes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.darkPurple(brightness),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your favorite recipes will appear here. Start exploring and add recipes you love!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.darkGrey(brightness),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 36),
            ElevatedButton.icon(
              icon: Icon(Icons.search_rounded, size: 20),
              label: Text(
                'Discover Recipes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple(brightness),
                foregroundColor: AppColors.white(brightness),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
                shadowColor: AppColors.primaryPurple(
                  brightness,
                ).withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesListView(
    BuildContext context,
    List<QueryDocumentSnapshot> favoriteDocs,
    User currentUser,
  ) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      physics: BouncingScrollPhysics(),
      itemCount: favoriteDocs.length,
      itemBuilder: (context, index) {
        final favorite = favoriteDocs[index];
        final recipeId = favorite['recipe_id'];
        final docId = favorite.id;

        return FutureBuilder<Recipe?>(
          future: fetchRecipe(recipeId),
          builder: (context, recipeSnapshot) {
            if (recipeSnapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard(context);
            }

            if (!recipeSnapshot.hasData || recipeSnapshot.data == null) {
              return _buildRecipeNotFoundCard(recipeId, docId, context);
            }

            final recipe = recipeSnapshot.data!;

            return _buildRecipeCard(context, recipe, docId, currentUser);
          },
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: cardElevation,
      shadowColor: AppColors.shadowColor(brightness),
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(contentPadding),
        child: Row(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: AppColors.lightPurple(brightness),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor(brightness),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple(brightness),
                  ),
                  strokeWidth: 2,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.grey(brightness),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppColors.grey(brightness),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.grey(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeNotFoundCard(
    String recipeId,
    String docId,
    BuildContext context,
  ) {
    final brightness = Theme.of(context).brightness;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: cardElevation,
      shadowColor: AppColors.shadowColor(brightness),
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: Padding(
        padding: const EdgeInsets.all(contentPadding),
        child: Row(
          children: [
            Container(
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                color: AppColors.grey(brightness),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor(brightness),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: AppColors.darkGrey(brightness),
                  size: 32,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe not found',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.darkPurple(brightness),
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'ID: $recipeId',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.darkGrey(brightness),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'This recipe may no longer be available',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.darkGrey(brightness).withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap:
                    () =>
                        _showDeleteConfirmation(context, docId, "this recipe"),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.deleteRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deleteRed.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.deleteRed,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    Recipe recipe,
    String docId,
    User currentUser,
  ) {
    final brightness = Theme.of(context).brightness;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: cardElevation,
      shadowColor: AppColors.shadowColor(brightness),
      shape: RoundedRectangleBorder(borderRadius: cardBorderRadius),
      child: InkWell(
        borderRadius: cardBorderRadius,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => RecipeDetailScreen(
                    recipe: recipe,
                    userId: currentUser.uid,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(contentPadding),
          child: Row(
            children: [
              Hero(
                tag: 'recipe-image-${recipe.id}',
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor(brightness),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.grey(brightness),
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: AppColors.darkGrey(brightness),
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple(brightness),
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightPurple(brightness),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondaryPurple(
                            brightness,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        recipe.category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkPurple(brightness),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap:
                      () =>
                          _showDeleteConfirmation(context, docId, recipe.name),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.deleteRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deleteRed.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.deleteRed,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
