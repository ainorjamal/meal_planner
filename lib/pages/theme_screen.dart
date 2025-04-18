import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/providers/theme_provider.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDarkMode,
            onChanged: (bool value) {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
    );
  }
}
