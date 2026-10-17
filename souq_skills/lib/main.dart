import 'package:flutter/material.dart';

import 'screens/auth/auth_screens.dart';
import 'screens/home/home_screens.dart';
import 'screens/listings/post_skill/post_skill_screens.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'widgets/souq_widgets.dart';

const souqGreen = Color(0xFF2D7357);
const souqNavy = Color(0xFF071A2A);
const souqCream = Color(0xFFF8FAF5);
const souqMint = Color(0xFF9AF0C5);
const souqLavender = Color(0xFF6650B5);
const souqGold = Color(0xFFE5A83B);

void main() {
  runApp(const SouqSkillsApp());
}

class SouqSkillsApp extends StatelessWidget {
  const SouqSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Souq Skills',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: souqCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: souqGreen,
          brightness: Brightness.light,
          surface: souqCream,
        ),
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: souqNavy,
            fontWeight: FontWeight.w800,
          ),
          headlineSmall: TextStyle(
            color: souqNavy,
            fontWeight: FontWeight.w800,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: souqCream,
          foregroundColor: souqNavy,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex = widget.initialIndex;

  final _pages = const [
    HomeScreen(),
    PlaceholderPage(
      title: 'Chats',
      description: 'Trade conversations will appear here in Phase 3.',
      icon: Icons.chat_bubble_outline,
    ),
    PostSkillSkillsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SouqBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
