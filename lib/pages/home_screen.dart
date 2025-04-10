import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
// Import screens from the screens directory
import '../screens/add_meal_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/meal_details_screen.dart';
import '../screens/recipes_screen.dart';
// Import the Firestore service
import '../services/firestore.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  Color primaryColor = Colors.green; // Your app's primary color

  // Initialize Firestore service
  final FirestoreService _firestoreService = FirestoreService();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search meals...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color:
                          _isDarkMode
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                    ),
                  ),
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  autofocus: true,
                )
                : Text('Meal Planner'),
        actions: [
          // Search icon
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Cancel' : 'Search',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
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
                  ).then((_) {
                    setState(() {});
                  });
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

  // Home tab content with Firestore integration
  Widget _buildHomeContent() {
    return _isSearching && _searchQuery.isNotEmpty
        ? _buildSearchResults()
        : _buildMealList();
  }

  // Stream builder for displaying all meals
  Widget _buildMealList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMeals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading meals: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final meals = snapshot.data?.docs ?? [];

        if (meals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_food, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No meals logged yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddMealScreen()),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                  icon: Icon(Icons.add),
                  label: Text('Add your first meal'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: meals.length,
          itemBuilder: (context, index) {
            final mealDoc = meals[index];
            final mealData = mealDoc.data() as Map<String, dynamic>?;
            final mealId = mealDoc.id;

            if (mealData == null) {
              return SizedBox.shrink();
            }

            final title = mealData['title'] ?? 'Untitled Meal';
            final description = mealData['description'] ?? 'No description';
            final time = mealData['time'] ?? '';
            final mealType = mealData['mealType'] ?? '';
            final isLogged = mealData['logged'] ?? false;

            // Get meal type icon
            IconData mealTypeIcon = _getMealTypeIcon(mealType);

            return Dismissible(
              key: Key(mealId),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: Text('Delete Meal'),
                        content: Text(
                          'Are you sure you want to delete this meal?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                );
              },
              onDismissed: (direction) async {
                try {
                  await _firestoreService.deleteMeal(mealId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Meal deleted'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          // Attempt to re-add the deleted meal
                          await _firestoreService.addMeal(
                            title: mealData['title'] ?? '',
                            description: mealData['description'] ?? '',
                            time: mealData['time'] ?? '',
                            mealType: mealData['mealType'],
                          );
                        },
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting meal: $e')),
                  );
                }
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getMealTypeColor(mealType),
                  child: Icon(mealTypeIcon, color: Colors.white),
                ),
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        SizedBox(width: 16),
                        if (isLogged)
                          Chip(
                            label: Text('Logged'),
                            backgroundColor: Colors.green.withOpacity(0.2),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ],
                ),
                isThreeLine: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => MealDetailsScreen(
                            mealId: mealId,
                            mealName: title,
                            ingredients: description,
                          ),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },

                // Modify the trailing property in your ListTile within the _buildMealList() method
                // Replace the existing trailing: IconButton(...) with this:
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      tooltip: 'Edit meal',
                      onPressed: () {
                        // Create a map with the meal data and ID for editing
                        final editableMeal = {
                          'id': mealId,
                          'title': title,
                          'description': description,
                          'time': time,
                          'mealType': mealType,
                          'logged': isLogged,
                        };

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AddMealScreen(mealToEdit: editableMeal),
                          ),
                        ).then((_) {
                          setState(() {});
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete meal',
                      onPressed: () async {
                        bool confirmDelete =
                            await showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text('Delete Meal'),
                                    content: Text(
                                      'Are you sure you want to delete this meal?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text('Delete'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                            ) ??
                            false;

                        if (confirmDelete) {
                          try {
                            await _firestoreService.deleteMeal(mealId);
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Meal deleted'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () async {
                                    // Attempt to re-add the deleted meal
                                    await _firestoreService.addMeal(
                                      title: mealData['title'] ?? '',
                                      description:
                                          mealData['description'] ?? '',
                                      time: mealData['time'] ?? '',
                                      mealType: mealData['mealType'],
                                    );
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error deleting meal: $e'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to get meal type icon
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.apple;
      default:
        return Icons.restaurant;
    }
  }

  // Helper method to get meal type color
  Color _getMealTypeColor(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.indigo;
      case 'snack':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // Stream builder for displaying search results
  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMeals(), // Use the existing stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error searching meals: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final allMeals = snapshot.data?.docs ?? [];
        final searchResults =
            allMeals.where((doc) {
              final mealData = doc.data() as Map<String, dynamic>?;
              if (mealData == null) return false;
              final title = (mealData['title'] as String?)?.toLowerCase() ?? '';
              final description =
                  (mealData['description'] as String?)?.toLowerCase() ?? '';
              final mealType =
                  (mealData['mealType'] as String?)?.toLowerCase() ?? '';
              return title.contains(_searchQuery.toLowerCase()) ||
                  description.contains(_searchQuery.toLowerCase()) ||
                  mealType.contains(_searchQuery.toLowerCase());
            }).toList();

        if (searchResults.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No results found for "$_searchQuery"',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: searchResults.length,
          itemBuilder: (context, index) {
            final mealDoc = searchResults[index];
            final mealData = mealDoc.data() as Map<String, dynamic>?;
            final mealId = mealDoc.id;

            if (mealData == null) {
              return SizedBox.shrink();
            }

            final title = mealData['title'] ?? 'Untitled Meal';
            final description = mealData['description'] ?? 'No description';
            final time = mealData['time'] ?? '';
            final mealType = mealData['mealType'] ?? '';
            final isLogged = mealData['logged'] ?? false;

            // Get meal type icon
            IconData mealTypeIcon = _getMealTypeIcon(mealType);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getMealTypeColor(mealType),
                child: Icon(mealTypeIcon, color: Colors.white),
              ),
              title: Text(title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      if (isLogged)
                        Chip(
                          label: Text('Logged'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MealDetailsScreen(
                          mealId: mealId,
                          mealName: title,
                          ingredients: description,
                        ),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
            );
          },
        );
      },
    );
  }

  // Profile tab content
  Widget _buildProfileContent() {
    // Get current user from Firebase Auth
    final User? currentUser = authService.value.currentUser;

    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'User not logged in',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await authService.value.signOut();
              },
              child: Text('Return to Login'),
            ),
          ],
        ),
      );
    }

    // Get user email from Firebase Auth
    final String userEmail = currentUser.email ?? 'No email available';
    final String userId = currentUser.uid;

    // Return the profile UI with Firestore data
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading profile: ${snapshot.error}',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // Get user data from Firestore
        Map<String, dynamic>? userData =
            snapshot.data?.data() as Map<String, dynamic>?;

        // Default username if not set in Firestore
        String userName = userData?['displayName'] ?? 'User';
        String photoUrl = userData?['photoUrl'] ?? '';

        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile picture
              photoUrl.isNotEmpty
                  ? CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(photoUrl),
                  )
                  : CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
              SizedBox(height: 16),

              // User name
              Text(
                userName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),

              // User email
              Text(userEmail, style: TextStyle(color: Colors.grey)),
              SizedBox(height: 32),

              // Edit profile button
              ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Edit Profile'),
                onPressed: () {
                  _showEditProfileDialog(context, userName);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
              SizedBox(height: 24),

              // Divider
              Divider(),

              // Settings and options
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {
                  // Navigate to settings screen
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite),
                title: Text('Favorite Recipes'),
                onTap: () {
                  // Navigate to favorites screen
                },
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text('Meal History'),
                onTap: () {
                  // Navigate to meal history screen
                },
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: Text('Help & Support'),
                onTap: () {
                  // Navigate to help screen
                },
              ),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  bool confirm =
                      await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text('Logout'),
                              content: Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed:
                                      () => Navigator.of(context).pop(true),
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
        );
      },
    );
  }

  // Add this method to show the edit profile dialog
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                // Could add more fields here (phone, location, etc.)
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Get the current user ID
                  final User? user = authService.value.currentUser;
                  if (user != null && nameController.text.trim().isNotEmpty) {
                    try {
                      // Update the display name in Firestore
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                            'displayName': nameController.text.trim(),
                            // Keep other fields that might exist in the document
                          }, SetOptions(merge: true));

                      Navigator.of(context).pop();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Profile updated successfully')),
                      );
                    } catch (e) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating profile: $e')),
                      );
                    }
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }
}
