import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';

extension AppNavigation on BuildContext {
  /// Opens [route] and completes with the value the screen returns, if any.
  Future<Object?> open(String route, {Object? args}) =>
      Navigator.of(this).pushNamed<Object?>(route, arguments: args);

  void replaceWith(String route, {Object? args}) =>
      Navigator.of(this).pushReplacementNamed(route, arguments: args);

  /// Clears the back stack, which also switches the main tab for tab routes.
  void resetTo(String route) =>
      Navigator.of(this).pushNamedAndRemoveUntil(route, (_) => false);

  /// Clears a finished flow, leaving Home underneath the opened screen.
  void resetThenOpen(String route, {Object? args}) => Navigator.of(this)
    ..pushNamedAndRemoveUntil(AppRoutes.home, (_) => false)
    ..pushNamed(route, arguments: args);

  void back([Object? result]) => Navigator.of(this).pop(result);
}
