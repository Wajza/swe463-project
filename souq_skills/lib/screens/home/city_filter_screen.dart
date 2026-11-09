import 'package:flutter/material.dart';

class CityFilterScreen extends StatelessWidget {
  const CityFilterScreen({super.key});
  static const cities = ['Riyadh', 'Jeddah', 'Dammam', 'Makkah', 'Madinah', 'Online'];
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose city')),
    body: ListView(
      children: cities
          .map((city) => ListTile(
                leading: const Icon(Icons.location_city),
                title: Text(city),
                onTap: () => Navigator.pop(context, city),
              ))
          .toList(),
    ),
  );
}
