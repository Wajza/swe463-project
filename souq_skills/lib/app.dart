import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/services/repository.dart';

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
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRouter.onGenerateRoute,
        // Data lives in memory, so a browser refresh restarts from the welcome.
        onGenerateInitialRoutes: (_) => [
          AppRouter.onGenerateRoute(
            const RouteSettings(name: AppRoutes.welcome),
          ),
        ],
      ),
    );
  }
}
