import 'package:flutter/material.dart';

class RecipesScreen extends StatefulWidget {
  @override
  _RecipesScreenState createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final List<Recipe> _recipes = [
    Recipe(
      id: '1',
      name: 'Oatmeal with Berries',
      category: 'Breakfast',
      prepTime: 5,
      cookTime: 10,
      imageUrl: 'assets/oatmeal.jpg',
      ingredients: [
        '1 cup rolled oats',
        '2 cups milk or water',
        '1/4 cup mixed berries',
        '1 tbsp honey or maple syrup',
        'Pinch of salt',
      ],
      instructions: [
        'Combine oats, milk, and salt in a pot.',
        'Bring to a boil, then reduce heat and simmer for 5-7 minutes, stirring occasionally.',
        'Remove from heat and pour into a bowl.',
        'Top with berries and drizzle with honey or maple syrup.',
      ],
      isFavorite: true,
    ),
    Recipe(
      id: '2',
      name: 'Grilled Chicken Salad',
      category: 'Lunch',
      prepTime: 15,
      cookTime: 20,
      imageUrl: 'assets/chicken_salad.jpg',
      ingredients: [
        '2 chicken breasts',
        '4 cups mixed greens',
        '1 cucumber, sliced',
        '1 cup cherry tomatoes, halved',
        '1/4 cup olive oil',
        '2 tbsp lemon juice',
        'Salt and pepper to taste',
      ],
      instructions: [
        'Season chicken breasts with salt and pepper.',
        'Grill chicken for 6-8 minutes per side until fully cooked.',
        'Let chicken rest for 5 minutes, then slice.',
        'In a large bowl, combine greens, cucumber, and tomatoes.',
        'Whisk together olive oil and lemon juice for dressing.',
        'Top salad with sliced chicken and drizzle with dressing.',
      ],
      isFavorite: false,
    ),
    Recipe(
      id: '3',
      name: 'Spaghetti Bolognese',
      category: 'Dinner',
      prepTime: 20,
      cookTime: 45,
      imageUrl: 'assets/spaghetti.jpg',
      ingredients: [
        '1 lb ground beef',
        '1 onion, diced',
        '2 garlic cloves, minced',
        '1 carrot, diced',
        '1 celery stalk, diced',
        '1 can (28 oz) crushed tomatoes',
        '2 tbsp tomato paste',
        '1 tsp dried oregano',
        'Salt and pepper to taste',
        '1 lb spaghetti',
      ],
      instructions: [
        'Heat oil in a large pot and sauté onion, garlic, carrot, and celery until softened.',
        'Add ground beef and cook until browned.',
        'Stir in crushed tomatoes, tomato paste, and oregano.',
        'Simmer for 30 minutes, stirring occasionally.',
        'Meanwhile, cook spaghetti according to package directions.',
        'Drain pasta and serve topped with sauce.',
      ],
      isFavorite: true,
    ),
    Recipe(
      id: '4',
      name: 'Pancakes',
      category: 'Breakfast',
      prepTime: 10,
      cookTime: 15,
      imageUrl: 'assets/pancakes.jpg',
      ingredients: [
        '1 cup all-purpose flour',
        '2 tbsp sugar',
        '1 tsp baking powder',
        '1/2 tsp baking soda',
        '1/4 tsp salt',
        '1 cup buttermilk',
        '1 large egg',
        '2 tbsp melted butter',
        'Maple syrup for serving',
      ],
      instructions: [
        'In a large bowl, whisk together flour, sugar, baking powder, baking soda, and salt.',
        'In another bowl, whisk together buttermilk, egg, and melted butter.',
        'Pour wet ingredients into dry ingredients and stir until just combined.',
        'Heat a lightly oiled griddle or frying pan over medium-high heat.',
        'Pour 1/4 cup batter onto the griddle for each pancake.',
        'Cook until bubbles form, then flip and cook until browned on the other side.',
        'Serve with maple syrup.',
      ],
      isFavorite: false,
    ),
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
  ];

  List<Recipe> get _filteredRecipes {
    return _recipes.where((recipe) {
      // Apply category filter
      if (_selectedCategory != 'All' && recipe.category != _selectedCategory) {
        return false;
      }

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        return recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recipe.ingredients.any(
              (ingredient) =>
                  ingredient.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipes'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recipes or ingredients...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Category chips
          Container(
            height: 50,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              },
            ),
          ),
          // Recipes grid
          Expanded(
            child:
                _filteredRecipes.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_food, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No recipes found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : GridView.builder(
                      padding: EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _filteredRecipes[index];
                        return _buildRecipeCard(recipe);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => _navigateToRecipeDetail(recipe),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Center(child: Text(recipe.name)),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        recipe.isFavorite = !recipe.isFavorite;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        recipe.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: recipe.isFavorite ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    recipe.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${recipe.cookTime + recipe.prepTime} min',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Recipes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Categories', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _categories.map((category) {
                      final isSelected = _selectedCategory == category;

                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category : 'All';
                            Navigator.pop(context);
                          });
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.2),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _searchQuery = '';
                  });
                  Navigator.pop(context);
                },
                child: Text('Clear Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    // Navigate to recipe detail screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}

// Recipe detail screen
class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Details'),
        actions: [
          IconButton(
            icon: Icon(
              recipe.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: recipe.isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              // Toggle favorite status
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Share recipe
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: Center(child: Text(recipe.name)),
            ),
            // Recipe info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    recipe.category,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  // Time info
                  Row(
                    children: [
                      _buildTimeInfo('Prep', recipe.prepTime),
                      SizedBox(width: 24),
                      _buildTimeInfo('Cook', recipe.cookTime),
                      SizedBox(width: 24),
                      _buildTimeInfo(
                        'Total',
                        recipe.prepTime + recipe.cookTime,
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  // Ingredients
                  _buildSectionTitle('Ingredients'),
                  SizedBox(height: 8),
                  ...recipe.ingredients
                      .map(
                        (ingredient) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                size: 12,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Expanded(child: Text(ingredient)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  Divider(height: 32),
                  // Instructions
                  _buildSectionTitle('Instructions'),
                  SizedBox(height: 8),
                  ...List.generate(
                    recipe.instructions.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text(recipe.instructions[index])),
                        ],
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTimeInfo(String label, int minutes) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$minutes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(' min'),
          ],
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

// Model class for recipe
class Recipe {
  final String id;
  final String name;
  final String category;
  final int prepTime;
  final int cookTime;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  bool isFavorite;

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.prepTime,
    required this.cookTime,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    this.isFavorite = false,
  });
}
