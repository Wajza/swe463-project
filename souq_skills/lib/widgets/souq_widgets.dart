import 'package:flutter/material.dart';

import '../main.dart';
import '../models/skill_listing.dart';

class SouqButton extends StatelessWidget {
  const SouqButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.showArrow = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (showArrow) ...[
          const SizedBox(width: 14),
          const Icon(Icons.arrow_forward, size: 20),
        ],
      ],
    );
    final button = outlined
        ? OutlinedButton(onPressed: onPressed, child: content)
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: souqGreen,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            child: content,
          );
    return SizedBox(width: double.infinity, height: 60, child: button);
  }
}

class SouqLogo extends StatelessWidget {
  const SouqLogo({this.small = false, super.key});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 64.0 : 136.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: souqGreen,
        borderRadius: BorderRadius.circular(small ? 20 : 42),
        boxShadow: small
            ? null
            : [
                BoxShadow(
                  color: souqGreen.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Icon(Icons.notes_rounded, color: souqMint, size: small ? 34 : 70),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    required this.title,
    required this.description,
    this.icon = Icons.construction_outlined,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          CircleAvatar(
            radius: 42,
            backgroundColor: souqGreen.withValues(alpha: 0.12),
            child: Icon(icon, size: 42, color: souqGreen),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: souqNavy, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: Colors.black54, height: 1.5),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 32),
            ...actions.expand((action) => [action, const SizedBox(height: 12)]),
          ],
        ],
      ),
    );
  }
}

class SkillListingCard extends StatelessWidget {
  const SkillListingCard({
    required this.listing,
    required this.accentColor,
    required this.onTap,
    super.key,
  });

  final SkillListing listing;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 136,
              height: 178,
              color: accentColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text('${listing.distance}  km'),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Text(
                      listing.offers.substring(0, 1),
                      style: const TextStyle(
                        color: souqNavy,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: souqGreen,
                          child: Text(
                            listing.owner.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            listing.owner,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('★ ${listing.rating}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      listing.category.toUpperCase(),
                      style: const TextStyle(
                        color: souqGreen,
                        fontSize: 10,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      listing.title,
                      style: const TextStyle(
                        color: souqNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Offers ${listing.offers}  ⇄  Wants ${listing.wants}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SouqBottomNavigationBar extends StatelessWidget {
  const SouqBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chats',
        ),
        NavigationDestination(icon: Icon(Icons.add), label: 'Post'),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Wallet',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
