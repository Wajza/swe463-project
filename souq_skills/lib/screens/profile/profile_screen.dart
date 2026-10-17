import 'package:flutter/material.dart';

import '../../main.dart';
import '../safety/safety_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 42)),
          const SizedBox(height: 12),
          const Text(
            'Your profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: souqNavy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Verified member',
            textAlign: TextAlign.center,
            style: TextStyle(color: souqGreen),
          ),
          const SizedBox(height: 28),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Trade history'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Your reviews'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Safety Centre'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SafetyCentreScreen(),
                    ),
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
