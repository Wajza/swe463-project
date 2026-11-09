import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/app_page.dart';

class CityFilterScreen extends StatelessWidget {
  const CityFilterScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Choose city',
    children: [
      for (final city in AppOptions.cities)
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(city),
            onTap: () => context.back(city),
          ),
        ),
    ],
  );
}
