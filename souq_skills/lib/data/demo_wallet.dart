import '../models/wallet_snapshot.dart';

// Temporary display data matching Figma.
// Summary totals are supplied independently of the recent activity list.
const demoWallet = WalletSnapshot(
  balance: 120,
  earned: 180,
  spent: 60,
  transactions: [
    WalletActivity(
      title: 'Trade completed with Sara',
      subtitle: '12 Jun · Arabic practice',
      amount: 20,
      dateLabel: '12 June 2025 · 8:35 PM',
      reference: 'SS-240612-018',
      kind: WalletActivityKind.earned,
    ),
    WalletActivity(
      title: 'Used for pottery lesson',
      subtitle: '8 Jun · 1.5 hours',
      amount: -15,
      dateLabel: '8 June 2025',
      reference: 'DEMO-POTTERY-002',
      kind: WalletActivityKind.spent,
    ),
    WalletActivity(
      title: 'Welcome bonus',
      subtitle: '1 Jun · Account verified',
      amount: 100,
      dateLabel: '1 June 2025',
      reference: 'DEMO-WELCOME-003',
      kind: WalletActivityKind.bonus,
    ),
    WalletActivity(
      title: 'Group trade completed',
      subtitle: '28 May · 3 members',
      amount: 30,
      dateLabel: '28 May 2025',
      reference: 'DEMO-GROUP-004',
      kind: WalletActivityKind.group,
    ),
  ],
);
