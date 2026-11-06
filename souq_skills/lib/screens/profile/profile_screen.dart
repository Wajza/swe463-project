import 'badges_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/profile_provider.dart';
import 'edit_profile_screen.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../safety/safety_screens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProfileHeader(),
                const SizedBox(height: 24),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      _ProfileStat(value: '4.9', label: 'Rating'),
                      _ProfileStat(value: '18', label: 'Completed'),
                      _ProfileStat(value: '2', label: 'Active'),
                      _ProfileStat(value: '27', label: 'Reviews'),
                    ],
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: souqMint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: souqGreen),
                          Text(
                            'Neighborhood Mentor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('760 / 1,000 XP'),
                        ],
                      ),
                      SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: 0.76,
                        minHeight: 8,
                        color: souqLavender,
                        backgroundColor: Color(0xFFE5DEF5),
                      ),
                      SizedBox(height: 12),
                      Text('240 XP to Community Guide'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Skills',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                const _SkillGroup(
                  title: 'I CAN SHARE',
                  skills: ['Excel dashboards', 'CV writing'],
                  color: Color(0xFFD0EADD),
                ),
                const SizedBox(height: 16),
                const _SkillGroup(
                  title: 'I WANT TO LEARN',
                  skills: ['Brand design', 'Pottery'],
                  color: Color(0xFFBFEAF9),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Badges',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BadgesScreen(),
                          ),
                        );
                      },
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _BadgePreview(
                      label: 'Trusted',
                      icon: Icons.verified_user_outlined,
                      color: Color(0xFFE5F4CF),
                    ),
                    _BadgePreview(
                      label: 'Connector',
                      icon: Icons.people_outline,
                      color: Color(0xFFE5DEF5),
                    ),
                    _BadgePreview(
                      label: '5-star',
                      icon: Icons.auto_awesome,
                      color: Color(0xFFFFE5D8),
                    ),
                    _BadgePreview(
                      label: 'Guide',
                      icon: Icons.star_outline,
                      color: Color(0xFFF0F5E8),
                      locked: true,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Your activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      const ListTile(
                        enabled: false,
                        leading: Icon(Icons.history),
                        title: Text('Trade history'),
                        subtitle: Text('Connection pending'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        enabled: false,
                        leading: Icon(Icons.list_alt_outlined),
                        title: Text('My Trades'),
                        subtitle: Text('Connection pending'),
                        trailing: Icon(Icons.chevron_right),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Safety Centre'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const SafetyCentreScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: souqGreen,
          child: Text(
            profile.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.shownName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          '@${profile.username}',
          style: const TextStyle(color: souqGreen),
        ),
        if (profile.phoneVerified) ...[
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 17, color: souqGreen),
              SizedBox(width: 5),
              Text('Phone verified', style: TextStyle(color: souqGreen)),
            ],
          ),
        ],
        if (!profile.hideLocation) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_outlined, size: 17),
              const SizedBox(width: 4),
              Flexible(child: Text(profile.city)),
            ],
          ),
        ],
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(profile.bio, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const EditProfileScreen(),
              ),
            );
          },
          child: const Text('Edit profile'),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: souqNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SkillGroup extends StatelessWidget {
  const _SkillGroup({
    required this.title,
    required this.skills,
    required this.color,
  });

  final String title;
  final List<String> skills;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in skills)
              Chip(
                label: Text(skill),
                backgroundColor: color,
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgePreview extends StatelessWidget {
  const _BadgePreview({
    required this.label,
    required this.icon,
    required this.color,
    this.locked = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: souqGreen),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
