import 'package:flutter/material.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/loading_state.dart';
import 'package:souq_skills/widgets/profile_header.dart';
import 'package:souq_skills/widgets/settings_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: FutureBuilder(
      future: ProfileService().getProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingState(message: 'Loading profile...');
        final user = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(24), children: [
          ProfileHeader(user: user),
          const SizedBox(height: 28),
          SettingsTile(title: 'Edit profile', icon: Icons.edit_outlined, onTap: () {}),
          SettingsTile(title: 'Account details', icon: Icons.person_outline, onTap: () {}),
          SettingsTile(title: 'Settings', icon: Icons.settings_outlined, onTap: () {}),
        ]);
      },
    ),
  );
}

