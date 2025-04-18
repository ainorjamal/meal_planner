import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            subtitle: const Text('Light or Dark mode'),
            onTap: () {
               Navigator.pushNamed(context, '/theme');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Push and sound settings'),
            onTap: () {
               Navigator.pushNamed(context, '/notifications');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Preferences'),
            subtitle: const Text('Language, layout, etc.'),
            onTap: () {
               Navigator.pushNamed(context, '/preferences');
            },
          ),
        ],
      ),
    );
  }
}
