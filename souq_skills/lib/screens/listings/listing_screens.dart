import 'package:flutter/material.dart';

import '../../main.dart';
import '../../widgets/souq_widgets.dart';
import '../trades/trade_screens.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing detail')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: souqMint.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.translate, size: 72, color: souqGreen),
          ),
          const SizedBox(height: 24),
          Text(
            'Conversational Arabic',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Noura wants to help you build confidence in everyday Arabic conversations.',
          ),
          const SizedBox(height: 24),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: souqGreen,
              child: Text('NS', style: TextStyle(color: Colors.white)),
            ),
            title: Text('Noura S.'),
            subtitle: Text('4.8 rating • Verified member'),
          ),
          const SizedBox(height: 20),
          SouqButton(
            label: 'Propose a trade',
            showArrow: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatNegotiateScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
