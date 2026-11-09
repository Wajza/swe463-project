import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/services/repository.dart';
import 'package:souq_skills/widgets/save_failure_banner.dart';

class SouqSkillsApp extends StatelessWidget {
  const SouqSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Repository.instance,
      builder: (context, _) => MaterialApp(
        title: 'Souq Skills',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: Repository.instance.settings.darkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        builder: (context, child) => SaveFailureBanner(child: child!),
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRouter.onGenerateRoute,
        // Always start at the gate, which restores the saved data first.
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(name: AppRoutes.welcome),
          ),
        ],
      ),
    );
  }
}
