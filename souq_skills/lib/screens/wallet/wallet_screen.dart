import 'package:flutter/material.dart';

import '../../main.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill wallet')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: souqNavy,
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available credits',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '120',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Skill credits',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const ListTile(
            leading: Icon(Icons.add_circle, color: souqGreen),
            title: Text('Welcome bonus'),
            subtitle: Text('Today'),
            trailing: Text('+120'),
          ),
          const ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('No trades yet'),
            subtitle: Text('Your trade history will appear here'),
          ),
        ],
      ),
    );
  }
}
