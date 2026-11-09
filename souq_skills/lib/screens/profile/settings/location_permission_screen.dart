import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/feedback.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/services/profile_service.dart';
import 'package:souq_skills/widgets/souq_button.dart';
import 'package:souq_skills/widgets/status_page.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  void _allow(BuildContext context) {
    ProfileService().updateSettings(
      (current) => current.copyWith(locationVisible: true),
    );
    context.back();
    context.showMessage('Location enabled');
  }

  Future<void> _chooseCity(BuildContext context) async {
    final city = await context.open(AppRoutes.cityFilter);
    if (city is! String || !context.mounted) return;
    ProfileService().setCity(city);
    context.back();
    context.showMessage('City set to $city');
  }

  @override
  Widget build(BuildContext context) => StatusPage(
    pageTitle: 'Location',
    icon: Icons.location_on_outlined,
    title: 'Find skills near you',
    message: 'Use your location, or choose your city yourself.',
    actions: [
      SouqButton(label: 'Allow location', onPressed: () => _allow(context)),
      SouqButton(
        label: 'Choose city manually',
        outlined: true,
        onPressed: () => _chooseCity(context),
      ),
    ],
  );
}
