import 'package:flutter/material.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/widgets/category_icon.dart';

class CategoryFilterScreen extends StatelessWidget {
  const CategoryFilterScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose category')),
    body: ListView(padding: const EdgeInsets.all(20), children: CategoryConfig.names.map((category) => ListTile(
      leading: CategoryIcon(category: category, size: 44), title: Text(category),
      onTap: () => Navigator.pop(context, category),
    )).toList()),
  );
}
