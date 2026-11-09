import 'package:flutter/material.dart';
import 'package:souq_skills/core/app_options.dart';

class CityField extends StatelessWidget {
  const CityField({required this.value, required this.onChanged, super.key});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: AppOptions.cities.contains(value) ? value : null,
      decoration: const InputDecoration(labelText: 'City'),
      items: [
        for (final city in AppOptions.cities)
          DropdownMenuItem(value: city, child: Text(city)),
      ],
      onChanged: (city) {
        if (city != null) onChanged(city);
      },
    ),
  );
}
