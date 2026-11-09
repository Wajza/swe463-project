import 'package:flutter/material.dart';
import 'package:souq_skills/screens/chats/chats_screen.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/screens/listings/post_skill/post_skill_screen.dart';
import 'package:souq_skills/screens/profile/profile_screen.dart';
import 'package:souq_skills/screens/wallet/wallet_screen.dart';
import 'package:souq_skills/widgets/app_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  const MainShell({this.initialIndex = homeTab, super.key});

  static const homeTab = 0;
  static const chatsTab = 1;
  static const postTab = 2;
  static const walletTab = 3;
  static const profileTab = 4;

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;

  static const _pages = <Widget>[
    HomeScreen(),
    ChatsScreen(),
    PostSkillScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    // Back returns to Home from any other tab before leaving the app.
    canPop: _selectedIndex == MainShell.homeTab,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) setState(() => _selectedIndex = MainShell.homeTab);
    },
    child: Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: AppBottomNavigation(
        index: _selectedIndex,
        onChanged: (index) => setState(() => _selectedIndex = index),
      ),
    ),
  );
}
