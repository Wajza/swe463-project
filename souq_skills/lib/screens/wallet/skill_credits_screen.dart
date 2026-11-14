import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/data/wallet_repository.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/section_header.dart';

/// How skill credits work, as the wallet actually applies them. Every
/// amount comes from [WalletDocument], which the Firestore rules check, so
/// this page cannot drift from what members are paid.
class SkillCreditsScreen extends StatelessWidget {
  const SkillCreditsScreen({super.key});

  static const earning = [
    (
      symbol: '${WalletDocument.welcomeCredits}',
      title: 'Welcome credits',
      description:
          'Every new account starts with ${WalletDocument.welcomeCredits} '
          'credits, added once.',
    ),
    (
      symbol: '+${WalletDocument.completionReward}',
      title: 'Complete a trade',
      description:
          'You and the other member each earn '
          '${WalletDocument.completionReward} credits when a trade is '
          'completed, whatever its length.',
    ),
    (
      symbol: '+${WalletDocument.groupReward}',
      title: 'Complete a group trade',
      description:
          'Each member gets ${WalletDocument.groupReward} credits once '
          'every member has confirmed the group trade.',
    ),
  ];

  static const spending = [
    (
      icon: Icons.swap_horiz,
      title: 'Offer credits instead of a skill',
      description:
          "When the other member doesn't need a skill you offer, you can "
          'propose a trade paid in credits.',
    ),
    (
      icon: Icons.lock_clock_outlined,
      title: 'Held until the trade is completed',
      description:
          'Credits you offer are held while the trade is active and only '
          'move to the other member when it is completed.',
    ),
    (
      icon: Icons.account_balance_wallet_outlined,
      title: 'Only what you have available',
      description:
          'You can offer up to your balance, minus credits already held '
          'for your other active trades.',
    ),
    (
      icon: Icons.handshake_outlined,
      title: 'Earned by trading',
      description:
          'Souq Skills has no way to buy credits or cash them out, and they '
          "can't be sent to another member outside a trade.",
    ),
  ];

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Skill credits',
    children: [
      Card(
        color: context.colors.primaryContainer,
        child: ListTile(
          leading: Icon(
            Icons.auto_awesome,
            color: context.colors.onPrimaryContainer,
          ),
          title: const Text(
            "Use credits when a direct skill swap isn't possible.",
          ),
        ),
      ),
      const SectionHeader(title: 'Earning credits'),
      for (final item in earning)
        Card(
          child: ListTile(
            leading: SizedBox(
              width: 48,
              child: Text(
                item.symbol,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge?.copyWith(
                  color: context.colors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item.title),
            subtitle: Text(item.description),
          ),
        ),
      const SectionHeader(title: 'Spending credits'),
      for (final item in spending)
        Card(
          child: ListTile(
            leading: Icon(item.icon, color: context.colors.primary),
            title: Text(item.title),
            subtitle: Text(item.description),
          ),
        ),
    ],
  );
}
