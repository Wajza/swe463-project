import 'package:flutter/material.dart';
import 'package:souq_skills/screens/shell/main_shell.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/chat_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/souq_logo.dart';
import 'package:souq_skills/widgets/status_page.dart';

import 'onboarding_screen.dart';

/// Loads the saved data and sign-in, then opens the app or the welcome screen.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  final _repository = Repository.instance;
  Future<void>? _restoring;
  bool _resumed = false;

  @override
  void initState() {
    super.initState();
    if (!_repository.isRestored) _restoring = _restore();
  }

  /// Each step is skipped once done, so a retry only repeats what failed.
  Future<void> _restore() async {
    if (!_repository.isRestored) {
      await Future.wait([
        _repository.restore(),
        AuthService().restoreSession(),
      ]);
    }
    // After the saved data, which would otherwise replace the profile.
    await AuthService().loadSessionProfile();
    // A session restored from an earlier visit starts its chats here.
    ChatService.syncSession();
    if (!_resumed) {
      _resumed = true;
      MemberSimulator().resumePendingProposals();
    }
  }

  void _retry() => setState(() {
    _restoring = _restore();
  });

  Widget _buildDestination() =>
      AuthService().isSignedIn ? const MainShell() : const OnboardingScreen();

  @override
  Widget build(BuildContext context) {
    if (_restoring == null) return _buildDestination();
    return FutureBuilder<void>(
      future: _restoring,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [SouqLogo(small: true), CircularProgressIndicator()],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          // The page gives no details, so the reason goes to the console.
          debugPrint('Could not load your data: ${snapshot.error}');
          return StatusPage(
            icon: Icons.cloud_off_outlined,
            showBackButton: false,
            title: 'Could not load your data',
            message: 'Something went wrong while opening your saved data.',
            action: SouqButton(label: 'Try again', onPressed: _retry),
          );
        }
        return _buildDestination();
      },
    );
  }
}
