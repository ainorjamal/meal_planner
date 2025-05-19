// ignore: depend_on_referenced_packages
// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:meal_planner/pages/home_screen.dart';
import '../auth/auth_service.dart';
import '../screens/calendar_screen.dart';
import '../screens/recipes_screen.dart';
import 'package:provider/provider.dart'; 
import '/providers/theme_provider.dart'; 

// Centralized color palette for app-wide consistency
class AppColors {
  static const Color primaryPurple = Color(0xFF6750A4);
  static const Color secondaryPurple = Color(0xFF9A82DB);
  static const Color lightPurple = Color(0xFFE6DFFF);
  static const Color darkPurple = Color(0xFF4A3880);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF333333);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF43A047);

  // Get colors based on brightness mode
  static Color getCardColor(bool isDarkMode) =>
      isDarkMode ? Colors.grey.shade800 : Colors.white;

  static Color getTextColor(bool isDarkMode) =>
      isDarkMode ? Colors.white : darkGrey;

  static Color getSubtitleColor(bool isDarkMode) =>
      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
}

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _currentIndex = 3; // Set to 3 for Profile tab
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _isDarkMode ? AppColors.darkGrey : AppColors.lightGrey,
      appBar: _buildAppBar(),
      body: _buildProfileContent(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // MARK: - UI Building Methods

  // App Bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primaryPurple,
      title: const Text(
        'My Profile',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primaryPurple,
        unselectedItemColor:
            _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        onTap: _handleNavBarTap,
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
    );
  }

  // Handle navigation bar taps
  void _handleNavBarTap(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = HomeScreen();
        break;
      case 1:
        destination = CalendarScreen();
        break;
      case 2:
        destination = RecipesScreen();
        break;
      default:
        return; // We're already on the profile tab
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  // Main Profile Content
  Widget _buildProfileContent() {
    // Get current user from Firebase Auth
    final User? currentUser = authService.value.currentUser;

    if (currentUser == null) {
      return _buildNotLoggedInView();
    }

    // Get user email and ID
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView();
        }

        if (snapshot.hasError) {
          return _buildErrorView(snapshot.error);
        }

        // Get user data from Firestore
        Map<String, dynamic>? userData =
            snapshot.data?.data() as Map<String, dynamic>?;
        String userName = userData?['displayName'] ?? 'User';
        String photoUrl = userData?['photoUrl'] ?? '';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(userName, userEmail, photoUrl),
               _buildStatisticsSection(),
              _buildSettingsSection(),
              _buildAccountSection(),
              SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // Not logged in view
  Widget _buildNotLoggedInView() {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () async {
              await authService.value.signOut();
            },
            child: Text('Return to Login'),
          ),
        ],
      ),
    );
  }

  // Loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPurple),
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Error view
  Widget _buildErrorView(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.errorRed),
            SizedBox(height: 16),
            Text(
              'Error loading profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : AppColors.darkGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.errorRed),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  // Redesigned Profile header section
    Widget _buildProfileHeader(
      String userName,
      String userEmail,
      String photoUrl,
    ) {
      // Accessing the ThemeProvider to check if dark mode is enabled
      final themeProvider = Provider.of<ThemeProvider>(context);

      // Adjust the background color based on the theme
      Color headerBackgroundColor = themeProvider.isDarkMode ? Colors.black : Colors.white;
      Color profileTextColor = themeProvider.isDarkMode ? Colors.white : AppColors.primaryPurple;
      Color emailTextColor = themeProvider.isDarkMode ? Colors.white70 : AppColors.secondaryPurple;
      Color buttonColor = themeProvider.isDarkMode ? AppColors.primaryPurple.withOpacity(0.8) : AppColors.primaryPurple;

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: headerBackgroundColor, // Dynamic color based on theme
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        margin: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            // Top purple arc background
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryPurple, AppColors.secondaryPurple],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
            ),

            // Profile content with overlapping avatar
            Container(
              transform: Matrix4.translationValues(0, -60, 0),
              child: Column(
                children: [
                  // Profile picture with elevated card effect
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: GestureDetector(
                      onTap: () {
                        // Show options to change profile picture
                        _showChangePhotoOptions();
                      },
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Hero(
                            tag: 'profile-pic',
                            child: photoUrl.isNotEmpty
                                ? CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(photoUrl),
                                  )
                                : CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppColors.lightPurple,
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                          ),
                          // Camera icon for changing photo - restyled
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primaryPurple,
                                  AppColors.secondaryPurple,
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // User info card
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ), // tighter all around
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // User name
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 21, // smaller font
                            fontWeight: FontWeight.w600,
                            color: profileTextColor, // Adjust color based on theme
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 2), // super tight spacing
                        // User email
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              253,
                              253,
                              253,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 16, // smaller font
                              color: emailTextColor, // Adjust color based on theme
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 8), // very compact
                        // Edit profile button
                        SizedBox(
                          width: 180,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 19,
                            ), // smaller icon
                            label: Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 18), // smaller font
                            ),
                            onPressed: () => _showEditProfileDialog(context, userName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor, // Adjust button color
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 7,
                              ), // tighter vertical
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 3), // minimal space at the bottom
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

     // Redesigned stat card with better animations and shadows
    Widget _buildStatCard(String title, String value, IconData icon) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!_isDarkMode)
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
          ],
        ),
        child: Center( // Centers the entire Column within the container
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertical centering
            crossAxisAlignment: CrossAxisAlignment.center, // Horizontal centering
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30, color: AppColors.secondaryPurple),
              SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Statistics section
    Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : AppColors.darkPurple,
                ),
              ),
              TextButton.icon(
                icon: Icon(Icons.bar_chart, size: 18),
                label: Text('View All'),
                onPressed: () {
                  // Navigate to detailed statistics
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondaryPurple,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // Fetch statistics dynamically
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserStatistics(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final stats = snapshot.data ?? {};

              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard('Total Meals', stats['totalMeals'].toString(), Icons.restaurant),
                  _buildStatCard('Favorites', stats['favorites'].toString(), Icons.favorite),
                  _buildStatCard('This Week', stats['thisWeek'].toString(), Icons.calendar_today),
                  _buildStatCard('Streak', stats['streak'].toString(), Icons.local_fire_department),
                ],
              );
            },
          ),

          SizedBox(height: 24),
          Divider(
            color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            thickness: 1,
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  // Settings section
  Widget _buildSettingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : AppColors.darkPurple,
            ),
          ),
          SizedBox(height: 12),

          // Settings items with improved styling
          _buildSettingsItem(
            icon: Icons.settings,
            title: 'App Settings',
            subtitle: 'Theme, notifications, preferences',
            onTap: () {
               Navigator.pushNamed(context, '/settings');
            },
          ),
          _buildSettingsItem(
            icon: Icons.favorite,
            title: 'Favorite Recipes',
            subtitle: 'Your saved recipes',
            onTap: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),
          _buildSettingsItem(
            icon: Icons.history,
            title: 'Meal History',
            subtitle: 'Past meals and analytics',
            onTap: () {
              Navigator.pushNamed(context, '/mealHistory');
            },
          ),
          _buildSettingsItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'FAQs, contact support',
            onTap: () {
              Navigator.pushNamed(context, '/helpSupport');
            },
          ),
          SizedBox(height: 12),
          Divider(
            color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            thickness: 1,
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  // Account section (logout, delete)
  Widget _buildAccountSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : AppColors.darkPurple,
            ),
          ),
          SizedBox(height: 12),

          // Danger zone
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _handleLogout(),
          ),
          _buildSettingsItem(
            icon: Icons.delete_forever,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and data',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _handleDeleteAccount(),
          ),
        ],
      ),
    );
  }

  // Settings item with improved design and ripple effect
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppColors.lightPurple.withOpacity(0.3),
          highlightColor: AppColors.lightPurple.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.secondaryPurple).withOpacity(
                      0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color:
                        iconColor ??
                        (_isDarkMode
                            ? AppColors.lightPurple
                            : AppColors.secondaryPurple),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              textColor ??
                              (_isDarkMode ? Colors.white : AppColors.darkGrey),
                        ),
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  _isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                      _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Interactive Methods

  // Show options to change profile photo
  void _showChangePhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: AppColors.secondaryPurple,
                  ),
                  title: Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement photo picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gallery picker would open here')),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: AppColors.secondaryPurple,
                  ),
                  title: Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    // Implement camera
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Camera would open here')),
                    );
                  },
                ),
                if (_hasExistingPhoto()) // Only show if user has a profile photo
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      'Remove Current Photo',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleRemovePhoto();
                    },
                  ),
              ],
            ),
          ),
    );
  }

  // Check if user has existing photo
  bool _hasExistingPhoto() {
    // Implement logic to check if user has photo
    return true; // Placeholder
  }

  // Handle removing photo
  void _handleRemovePhoto() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove Photo'),
            content: Text(
              'Are you sure you want to remove your profile photo?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement photo removal
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile photo removed'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('Remove'),
              ),
            ],
          ),
    );
  }

  // Enhanced edit profile dialog with better design and validation
  void _showEditProfileDialog(BuildContext context, String currentName) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    // Password visibility toggles
    bool _obscurePassword = true;
    bool _obscureConfirmPassword = true;

    // Stateful builder to handle password visibility toggle
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: AppColors.primaryPurple,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Display name field with validation
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              labelStyle: TextStyle(
                                color: AppColors.secondaryPurple,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPurple,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: AppColors.secondaryPurple,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a display name';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),

                          // New password field with visibility toggle
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'New Password (Optional)',
                              labelStyle: TextStyle(
                                color: AppColors.secondaryPurple,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPurple,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: AppColors.secondaryPurple,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors.secondaryPurple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (!value.contains(RegExp(r'[0-9]'))) {
                                  return 'Password must contain a number';
                                }
                                if (!value.contains(RegExp(r'[a-zA-Z]'))) {
                                  return 'Password must contain a letter';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),

                          // Confirm new password field
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              labelStyle: TextStyle(
                                color: AppColors.secondaryPurple,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primaryPurple,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: AppColors.secondaryPurple,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: AppColors.secondaryPurple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (passwordController.text.isNotEmpty) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (value != passwordController.text) {
                                  return 'Passwords do not match';
                                }
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),

                          // Password requirements info with interactive checkmarks
                          if (passwordController.text.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightPurple.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.lightPurple,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkPurple,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  _buildPasswordRequirement(
                                    'At least 8 characters',
                                    passwordController.text.length >= 8,
                                  ),
                                  _buildPasswordRequirement(
                                    'Contains a number',
                                    passwordController.text.contains(
                                      RegExp(r'[0-9]'),
                                    ),
                                  ),
                                  _buildPasswordRequirement(
                                    'Contains a letter',
                                    passwordController.text.contains(
                                      RegExp(r'[a-zA-Z]'),
                                    ),
                                  ),
                                  _buildPasswordRequirement(
                                    'Passwords match',
                                    passwordController.text ==
                                            confirmPasswordController.text &&
                                        confirmPasswordController
                                            .text
                                            .isNotEmpty,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        // Validate form
                        if (formKey.currentState!.validate()) {
                          _updateUserProfile(
                            nameController.text.trim(),
                            passwordController.text.trim(),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text('Save Changes'),
                    ),
                  ],
                ),
          ),
    );
  }

  // Password requirement row with checkmark
  Widget _buildPasswordRequirement(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? AppColors.successGreen : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              color: isMet ? AppColors.darkPurple : Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

Future<Map<String, dynamic>> _fetchUserStatistics() async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return {
        'totalMeals': 0,
        'favorites': 0,
        'thisWeek': 0,
        'streak': 0,
      };
    }

    // Fetch all meals for both field variations
    final mealsSnapshot1 = await FirebaseFirestore.instance
        .collection('meals')
        .where('user_id', isEqualTo: userId)
        .get();

    final mealsSnapshot2 = await FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .get();

    final allMealDocs = [...mealsSnapshot1.docs, ...mealsSnapshot2.docs];

    // Favorites
    final favoritesSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('user_id', isEqualTo: userId)
        .get();

    // Meals this week
    final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final mealsThisWeekSnapshot1 = await FirebaseFirestore.instance
        .collection('meals')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .get();

    final mealsThisWeekSnapshot2 = await FirebaseFirestore.instance
        .collection('meals')
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .get();

    // ---------- STREAK LOGIC START ----------
    final now = DateTime.now();
    Set<String> uniqueMealDates = {};

    for (final doc in allMealDocs) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data['date'] is Timestamp) {
        final date = (data['date'] as Timestamp).toDate();
        final normalized = DateTime(date.year, date.month, date.day);
        uniqueMealDates.add(normalized.toIso8601String());
      }
    }

    int streak = 0;
    DateTime currentDay = DateTime(now.year, now.month, now.day);

    while (uniqueMealDates.contains(currentDay.toIso8601String())) {
      streak++;
      currentDay = currentDay.subtract(Duration(days: 1));
    }
    // ---------- STREAK LOGIC END ----------

    final totalMeals = allMealDocs.length;
    final totalFavorites = favoritesSnapshot.docs.length;
    final totalThisWeek =
        mealsThisWeekSnapshot1.docs.length + mealsThisWeekSnapshot2.docs.length;

    return {
      'totalMeals': totalMeals,
      'favorites': totalFavorites,
      'thisWeek': totalThisWeek,
      'streak': streak,
    };
  } catch (e) {
    print('Error fetching statistics: $e');
    return {
      'totalMeals': 0,
      'favorites': 0,
      'thisWeek': 0,
      'streak': 0,
    };
  }
}

  // Update user profile in Firestore
  Future<void> _updateUserProfile(
    String displayName,
    String newPassword,
  ) async {
    final User? user = authService.value.currentUser;
    if (user == null) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryPurple,
                ),
              ),
            ),
      );

      // Update display name in Firestore
      if (displayName.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // Update password if provided
      if (newPassword.isNotEmpty) {
        // In a real app, you would first re-authenticate the user
        // For this example, we'll just update the password
        await user.updatePassword(newPassword);
      }

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(12),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(12),
        ),
      );
    }
  }

  // Handle logout with confirmation
  void _handleLogout() async {
    bool confirm =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Logout'),
                content: Text('Are you sure you want to logout?'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text('Logout'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirm) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryPurple,
                  ),
                ),
              ),
        );

        // Sign out the user
        await authService.value.signOut();

        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to login screen
        Navigator.pushReplacementNamed(context, '/');
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Handle any errors during logout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  // Handle account deletion with confirmation
  void _handleDeleteAccount() async {
    // First confirmation
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Delete Account'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 36,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Warning: This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All your data will be permanently deleted, including:',
                    ),
                    SizedBox(height: 8),
                    ...[
                      'Profile information',
                      'Saved recipes',
                      'Meal plans',
                      'Preferences',
                    ].map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(item),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Delete Account'),
                  ),
                ],
              ),
        ) ??
        false;

    // Second confirmation with password
    if (confirmDelete) {
      final passwordController = TextEditingController();

      bool finalConfirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('Confirm Deletion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Please enter your password to confirm account deletion:',
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Confirm Deletion'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (finalConfirm) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryPurple,
                    ),
                  ),
                ),
          );

          final user = authService.value.currentUser;
          if (user != null) {
            // Re-authenticate user with password
            // In a real app, you'd use the entered password for authentication
            final AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: passwordController.text,
            );

            await user.reauthenticateWithCredential(credential);

            // Delete user data in Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .delete();

            // Delete meal plans, favorites, and other user-specific collections
            // This would involve additional Firestore queries and deletes

            // Delete Firebase user account
            await user.delete();

            // Close loading dialog
            if (context.mounted) Navigator.of(context).pop();

            // Navigate to login screen
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          }
        } catch (e) {
          // Close loading dialog if open
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.all(12),
            ),
          );
        }
      }
    }
  }
}
