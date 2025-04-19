import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Enhanced color palette with additional shades
class AppColors {
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryPurple = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color ultraLightPurple = Color(0xFFF3F0FF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color accentPurple = Color(0xFFB69DF8);
  static const Color textDark = Color(0xFF1D1B20);
  static const Color textLight = Color(0xFFF7F2FA);
  static const Color background = Color(0xFFF8F5FF);
  static const Color cardShadow = Color(0xFFDED6F8);
}

class MealHistoryScreen extends StatefulWidget {
  @override
  _MealHistoryScreenState createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  @override
  void initState() {
    super.initState();
    _checkMealsForHistory(); // Check meals when the screen is loaded
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Function to check meals and move expired ones to history
  void _checkMealsForHistory() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseFirestore.instance.collection('meals').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Get user_id (can be either 'user_id' or 'userId')
        final mealUserId = data['user_id'] ?? data['userId'];
        if (mealUserId != currentUser.uid) {
          print('Skipping ${doc.id} - not user\'s meal.');
          continue;
        }

        // Ensure the 'date' field exists and is a Timestamp
        if (data['date'] == null || data['date'] is! Timestamp) {
          print('Skipping ${doc.id} - invalid or missing date.');
          continue;
        }

        final mealDate = (data['date'] as Timestamp).toDate();
        final currentDate = DateTime.now();

        // If date is in the future, skip
        if (!mealDate.isBefore(currentDate)) {
          print('Skipping ${doc.id} - date is not in the past.');
          continue;
        }

        // Ready to move this meal
        final mealName = data['meal_name'] ??
            data['recipe_name'] ??
            data['mealName'] ??
            data['title'] ??
            'Unnamed Meal';

        final category = data['category'] ?? data['mealType'] ?? 'Uncategorized';

        print('Moving meal ${doc.id} to history');
        _moveMealToHistory(doc.id, mealName, category, mealDate, mealUserId);
      }
    } catch (e) {
      print('Error checking meals: $e');
    }
  }

  // Function to move a meal to the meal_history collection and delete from meals
  void _moveMealToHistory(String mealId, String mealName, String category, DateTime mealDate, String userId) {
    FirebaseFirestore.instance.collection('meal_history').add({
      'meal_name': mealName,
      'category': category,
      'date': mealDate.toIso8601String(),
      'user_id': userId, // Store user_id in history
      'timestamp': FieldValue.serverTimestamp(),
    }).then((_) {
      // After adding to meal history, delete the meal from the active meals collection
      FirebaseFirestore.instance.collection('meals').doc(mealId).delete().then((_) {
        print('Meal moved to history and removed from meals');
      }).catchError((error) {
        print('Error removing meal from meals collection: $error');
      });
    }).catchError((error) {
      print('Error moving meal to history: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Meal History',
          style: TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryPurple,
        elevation: 0,
        shape: RoundedRectangleBorder(
        ),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.darkPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.history_rounded, color: AppColors.textLight),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMealHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.ultraLightPurple,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 1,
                        )
                      ]
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
                          strokeWidth: 4,
                          backgroundColor: AppColors.lightPurple,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'Loading your meal history...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we prepare your past meals',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(24),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade100.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade200.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ]
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Error Loading Meal History',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {}); // Refresh the screen
                      },
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade700,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final mealHistory = snapshot.data ?? [];
          
          if (mealHistory.isEmpty) {
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.ultraLightPurple, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow.withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryPurple.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/empty_plate.png', // You would need to add this asset
                          fit: BoxFit.contain,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, _, __) => Icon(
                            Icons.restaurant_menu,
                            size: 70,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'No Meal History Yet',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkPurple,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Your past meals will appear here once they\'re completed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark.withOpacity(0.7),
                        height: 1.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Return to previous screen
                        },
                        icon: Icon(Icons.add_rounded),
                        label: Text('Plan New Meals'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.textLight,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Group meals by month
          Map<String, List<Map<String, dynamic>>> groupedMeals = {};
          for (var meal in mealHistory) {
            try {
              DateTime parsedDate = DateFormat.yMMMMd().parse(meal['date']);
              String month = DateFormat('MMMM yyyy').format(parsedDate);
              
              if (!groupedMeals.containsKey(month)) {
                groupedMeals[month] = [];
              }
              groupedMeals[month]!.add(meal);
            } catch (e) {
              String month = "Unknown Date";
              if (!groupedMeals.containsKey(month)) {
                groupedMeals[month] = [];
              }
              groupedMeals[month]!.add(meal);
            }
          }
          
          // Sort the keys (months) in descending order
          List<String> sortedMonths = groupedMeals.keys.toList()
            ..sort((a, b) {
              if (a == "Unknown Date") return 1;
              if (b == "Unknown Date") return -1;
              try {
                DateTime dateA = DateFormat('MMMM yyyy').parse(a);
                DateTime dateB = DateFormat('MMMM yyyy').parse(b);
                return dateB.compareTo(dateA);
              } catch (e) {
                return a.compareTo(b);
              }
            });
            
          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkPurple.withOpacity(0.3),
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
                            Icons.restaurant_rounded,
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
                                'Your Meal History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'You have ${mealHistory.length} meals in your history',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              for (String month in sortedMonths)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.accentPurple, AppColors.secondaryPurple],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                month,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...groupedMeals[month]!.map((meal) {
                        // Get icon based on category
                        IconData categoryIcon = Icons.restaurant_menu;
                        String category = meal['category'].toString().toLowerCase();
                        if (category.contains('breakfast')) {
                          categoryIcon = Icons.free_breakfast_rounded;
                        } else if (category.contains('lunch')) {
                          categoryIcon = Icons.lunch_dining_rounded;
                        } else if (category.contains('dinner')) {
                          categoryIcon = Icons.dinner_dining_rounded;
                        } else if (category.contains('snack')) {
                          categoryIcon = Icons.cookie_rounded;
                        }
                        
                        // Get color based on category
                        Color categoryColor = AppColors.primaryPurple;
                        if (category.contains('breakfast')) {
                          categoryColor = Colors.orange;
                        } else if (category.contains('lunch')) {
                          categoryColor = Colors.green;
                        } else if (category.contains('dinner')) {
                          categoryColor = Colors.indigo;
                        } else if (category.contains('snack')) {
                          categoryColor = Colors.amber;
                        }
                        
                       return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _animationController,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.2, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeOutExpo, 
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cardShadow.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(22),
                                splashColor: categoryColor.withOpacity(0.1),
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  _showMealDetailsDialog(
                                    context,
                                    meal['mealName'],
                                    meal['category'],
                                    meal['date'],
                                    categoryIcon,
                                    categoryColor,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 65,
                                        height: 65,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              categoryColor.withOpacity(0.8),
                                              categoryColor.withOpacity(0.6),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: categoryColor.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                              offset: Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            categoryIcon,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meal['mealName'],
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(30),
                                                    border: Border.all(
                                                      color: categoryColor.withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    meal['category'],
                                                    style: TextStyle(
                                                      color: categoryColor,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.ultraLightPurple,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.calendar_today_rounded,
                                                    size: 10,
                                                    color: AppColors.primaryPurple,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    meal['date'],
                                                    style: TextStyle(
                                                      color: AppColors.textDark.withOpacity(0.7),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.ultraLightPurple,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          color: AppColors.secondaryPurple,
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                
              SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  // Function to fetch meal history from Firestore
  Future<List<Map<String, dynamic>>> _fetchMealHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid; // Get the current user's ID

      if (userId == null) {
        print('No user is logged in');
        return []; // Return empty if no user is logged in
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('meal_history')
          .where('user_id', isEqualTo: userId) // Filter by user_id
          .get();

      final result = snapshot.docs.map((doc) {
        final data = doc.data();

        // Handle both 'user_id' and 'userId'
        final currentUserId = data['user_id'] ?? data['userId'] ?? 'Unknown user';  // Check both 'user_id' and 'userId'

        final mealName = data.containsKey('meal_name') && data['meal_name'].toString().isNotEmpty
            ? data['meal_name']
            : data.containsKey('recipe_name') && data['recipe_name'].toString().isNotEmpty
                ? data['recipe_name']
                : data.containsKey('mealName') && data['mealName'].toString().isNotEmpty
                    ? data['mealName']
                    : data.containsKey('title') && data['title'].toString().isNotEmpty
                        ? data['title']
                        : 'Unknown meal';

        final rawDate = data['date'];
        String formattedDate;

        if (rawDate is Timestamp) {
          formattedDate = DateFormat.yMMMMd().format(rawDate.toDate());
        } else if (rawDate is String) {
          try {
            final parsed = DateTime.parse(rawDate);
            formattedDate = DateFormat.yMMMMd().format(parsed);
          } catch (e) {
            formattedDate = 'Invalid date';
          }
        } else {
          formattedDate = 'Unknown date';
        }

        // Check both 'category' and 'mealType' fields for category
        final category = data['category'] ?? data['mealType'] ?? 'Unknown category';

        return {
          'mealName': mealName,
          'date': formattedDate,
          'category': category,
        };
      }).toList();

      return result;
    } catch (e) {
      print('Error fetching meals for user: $e');
      return [];
    }
  }

  void _showMealDetailsDialog(
    BuildContext context,
    String mealName,
    String category,
    String date,
    IconData icon,
    Color color,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                backgroundColor: Colors.transparent,
                elevation: 30,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, AppColors.ultraLightPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkPurple.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 2,
                        offset: Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Animated Glowing Icon with pulse effect
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.9, end: 1.1),
                        duration: Duration(seconds: 2),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value as double,
                            child: Container(
                              padding: EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    color.withOpacity(0.8),
                                    color.withOpacity(0.6),
                                  ],
                                  radius: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 46,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Meal Details',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.darkPurple,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: AppColors.darkPurple.withOpacity(0.3),
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Divider(
                        color: AppColors.lightPurple,
                        thickness: 2,
                        indent: 40,
                        endIndent: 40,
                      ),
                      SizedBox(height: 24),
                      _buildEnhancedDetailRow(Icons.restaurant_menu, 'Meal', mealName),
                      SizedBox(height: 18),
                      _buildEnhancedDetailRow(Icons.category_rounded, 'Category', category),
                      SizedBox(height: 18),
                      _buildEnhancedDetailRow(Icons.calendar_today_rounded, 'Date', date),
                      SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryPurple.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.check_circle_rounded, size: 20),
                          label: Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                            textStyle: TextStyle(fontSize: 16, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.ultraLightPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightPurple,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textDark.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}