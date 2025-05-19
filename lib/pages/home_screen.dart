// ignore: depend_on_referenced_packages
// ignore_for_file: library_private_types_in_public_api, depend_on_referenced_packages, unused_import, duplicate_ignore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
// Import screens from the screens directory
import '../screens/add_meal_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/meal_details_screen.dart';
import '../screens/recipes_screen.dart';
import '../screens/user_profile_screen.dart';
// Import the Firestore service
import '../services/firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class AppColors {
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryPurple = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color accentColor = Color(0xFFB69DF8);

  // Meal type colors
  static const Color breakfastColor = Color(0xFFFFA726);
  static const Color lunchColor = Color(0xFF66BB6A);
  static const Color dinnerColor = Color(0xFF5C6BC0);
  static const Color snackColor = Color(0xFFBF8C6D);
}


class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = false;
  Color primaryColor = Colors.green; // Your app's primary color
  List<DocumentSnapshot> _meals = [];

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
void initState() {
  super.initState();
  _loadAndFilterMeals();
}

Future<void> _loadAndFilterMeals() async {
  final combinedMeals = await _firestoreService.fetchCombinedMeals();
  await _autoMovePastMealsToHistory(combinedMeals);
  setState(() {
    _meals = combinedMeals.where((mealDoc) {
      // Refresh the list with future meals only
      final data = mealDoc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return !(data['date'] as Timestamp).toDate().isBefore(DateTime.now());
    }).toList();
  });
}

Future<void> _autoMovePastMealsToHistory(List<DocumentSnapshot> meals) async {
  final now = DateTime.now();
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  for (var mealDoc in meals) {
    final mealData = mealDoc.data() as Map<String, dynamic>?;
    if (mealData == null || mealData['date'] == null || mealData['time'] == null) continue;

    // Check if meal belongs to the current user
    final mealUserId = mealData['user_id'] ?? mealData['user_id'];
    if (mealUserId != currentUser.uid) {
      print('Skipping ${mealDoc.id} - not user\'s meal.');
      continue;
    }

    // Parse Firestore timestamp
    if (mealData['date'] is! Timestamp) {
      print('Skipping ${mealDoc.id} - invalid or missing date.');
      continue;
    }
    final date = (mealData['date'] as Timestamp).toDate();

    // Parse 12-hour time string
    final timeStr = mealData['time'];
    final timeParts = timeStr.split(' ');
    if (timeParts.length != 2) continue;

    final hourMinute = timeParts[0].split(':');
    if (hourMinute.length != 2) continue;

    int hour = int.tryParse(hourMinute[0]) ?? 0;
    final int minute = int.tryParse(hourMinute[1]) ?? 0;
    final String amPm = timeParts[1].toUpperCase();

    if (amPm == 'PM' && hour < 12) {
      hour += 12;
    } else if (amPm == 'AM' && hour == 12) {
      hour = 0;
    }

    final mealDateTime = DateTime(date.year, date.month, date.day, hour, minute);

    // If the meal is in the past, move it to history
    if (mealDateTime.isBefore(now)) {
      try {
        // Derive meal name and category with fallback
        final mealName = mealData['meal_name'] ??
            mealData['recipe_name'] ??
            mealData['mealName'] ??
            mealData['title'] ??
            'Unnamed Meal';

        final category = mealData['category'] ?? mealData['mealType'] ?? 'Uncategorized';

        // Optionally: add metadata like movedAt
        final updatedMealData = {
          ...mealData,
          'movedAt': Timestamp.now(),
          'meal_name': mealName,
          'category': category,
        };

        // Move to meal_history collection
        await FirebaseFirestore.instance
            .collection('meal_history')
            .doc(mealDoc.id)
            .set(updatedMealData);

        // Delete from original meals collection
        await FirebaseFirestore.instance
            .collection('meals')
            .doc(mealDoc.id)
            .delete();

        print("Moved meal '${mealDoc.id}' to history.");
      } catch (e) {
        print("Failed to move meal to history: $e");
      }
    }
  }
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
        ],
        automaticallyImplyLeading: false,
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor:
            _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
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
          } else if (index == 3) {
            // Profile tab - navigate to the new UserProfileScreen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
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
    if (_currentIndex == 0) {
      return _buildHomeContent();
    } else {
      // Fallback for any other tab index
      return _buildHomeContent();
    }
  }

  // Home tab content with Firestore integration
  Widget _buildHomeContent() {
    return _isSearching && _searchQuery.isNotEmpty
        ? _buildSearchResults()
        : _buildMealList();
  }

Widget _buildMealList() {
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return Center(child: Text("User not logged in"));
  }

  return FutureBuilder(
    future: Future.wait([
      // Query for meals with 'user_id'
      FirebaseFirestore.instance
          .collection('meals')
          .where('user_id', isEqualTo: userId)
          .get(),
      // Query for meals with 'userId'
      FirebaseFirestore.instance
          .collection('meals')
          .where('userId', isEqualTo: userId)
          .get(),
    ]),
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

      // Combine the results of both queries
      final mealsFromUserId = snapshot.data?[0].docs ?? [];
      final mealsFromUserId2 = snapshot.data?[1].docs ?? [];
      final combinedMeals = [...mealsFromUserId, ...mealsFromUserId2];

      if (combinedMeals.isEmpty) {
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

      final now = DateTime.now();

final filteredMeals = combinedMeals.where((mealDoc) {
  final mealData = mealDoc.data() as Map<String, dynamic>?;
  if (mealData == null || mealData['date'] == null || mealData['time'] == null) return false;

  // Convert Firestore Timestamp to DateTime
  DateTime date;
  if (mealData['date'] is Timestamp) {
    date = (mealData['date'] as Timestamp).toDate();
  } else {
    return false;
  }

  // Parse 12-hour time with AM/PM
  final timeStr = mealData['time'];
  final timeParts = timeStr.split(' ');
  if (timeParts.length != 2) return false;

  final hourMinute = timeParts[0].split(':');
  if (hourMinute.length != 2) return false;

  int hour = int.tryParse(hourMinute[0]) ?? 0;
  final int minute = int.tryParse(hourMinute[1]) ?? 0;
  final String amPm = timeParts[1].toUpperCase();

  if (amPm == 'PM' && hour < 12) {
    hour += 12;
  } else if (amPm == 'AM' && hour == 12) {
    hour = 0;
  }

  final mealDateTime = DateTime(
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  );

  return mealDateTime.isAfter(now) || mealDateTime.isAtSameMomentAs(now);
}).toList();


      return ListView.builder(
        itemCount: filteredMeals.length,
        itemBuilder: (context, index) {
          final mealDoc = filteredMeals[index];
          final mealData = mealDoc.data() as Map<String, dynamic>?;

          if (mealData == null) {
            return SizedBox.shrink();
          }

          final title = mealData['title'] ?? 'Untitled Meal';
          final description = mealData['description'] ?? 'No description';
          final time = mealData['time'] ?? '';
          final mealType = mealData['mealType'] ?? '';
          final isLogged = mealData['logged'] ?? false;

          // Handle date, which might be a Timestamp or null
          DateTime? date;
          if (mealData['date'] != null) {
            if (mealData['date'] is Timestamp) {
              date = (mealData['date'] as Timestamp).toDate();
            }
          }

          // Format date for display
          final String dateStr =
              date != null ? '${date.month}/${date.day}/${date.year}' : 'No date';

          // Get meal type icon
          IconData mealTypeIcon = _getMealTypeIcon(mealType);

          return Dismissible(
            key: Key(mealDoc.id),
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
                builder: (context) => AlertDialog(
                  title: Text('Delete Meal'),
                  content: Text('Are you sure you want to delete this meal?'),
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
                await _firestoreService.deleteMeal(mealDoc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Meal deleted'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await _firestoreService.addMeal(
                          title: mealData['title'] ?? '',
                          description: mealData['description'] ?? '',
                          time: mealData['time'] ?? '',
                          mealType: mealData['mealType'],
                          date: date ?? DateTime.now(),
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
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(time, style: TextStyle(fontSize: 13, color: Colors.grey)),
                      SizedBox(width: 16),
                      if (isLogged)
                        Chip(
                          label: Text('Logged'),
                          backgroundColor: Colors.green.withOpacity(0.2),
                          labelStyle: TextStyle(fontSize: 12, color: Colors.green),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                    builder: (context) => MealDetailsScreen(
                      mealId: mealDoc.id,
                      mealName: title,
                      ingredients: description,
                    ),
                  ),
                ).then((_) {
                  setState(() {});
                });
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    tooltip: 'Edit meal',
                    onPressed: () {
                      final editableMeal = {
                        'id': mealDoc.id,
                        'title': title,
                        'description': description,
                        'time': time,
                        'mealType': mealType,
                        'logged': isLogged,
                        'date': mealData['date'],
                      };

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
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
                      bool confirmDelete = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Meal'),
                          content: Text('Are you sure you want to delete this meal?'),
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
                      ) ?? false;

                      if (confirmDelete) {
                        try {
                          await _firestoreService.deleteMeal(mealDoc.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Meal deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  await _firestoreService.addMeal(
                                    title: mealData['title'] ?? '',
                                    description: mealData['description'] ?? '',
                                    time: mealData['time'] ?? '',
                                    mealType: mealData['mealType'],
                                    date: date ?? DateTime.now(),
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

            // Handle date, which might be a Timestamp or null
            DateTime? date;
            if (mealData['date'] != null) {
              if (mealData['date'] is Timestamp) {
                date = (mealData['date'] as Timestamp).toDate();
              }
            }

            // Format date for display
            final String dateStr =
                date != null
                    ? '${date.month}/${date.day}/${date.year}'
                    : 'No date';

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
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
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
}
