import 'package:flutter/material.dart';

import '../../main.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill wallet')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            color: souqNavy,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Available credits',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      IconButton(
                        tooltip:
                            _hideBalance ? 'Show balance' : 'Hide balance',
                        onPressed: () {
                          setState(() {
                            _hideBalance = !_hideBalance;
                          });
                        },
                        icon: Icon(
                          _hideBalance
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hideBalance ? '••••' : '120',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
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
