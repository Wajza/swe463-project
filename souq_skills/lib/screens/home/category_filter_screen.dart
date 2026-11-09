import 'package:flutter/material.dart';
import 'package:souq_skills/core/category_config.dart';
import 'package:souq_skills/core/navigation.dart';
import 'package:souq_skills/widgets/app_page.dart';
import 'package:souq_skills/widgets/category_icon.dart';

class CategoryFilterScreen extends StatelessWidget {
  const CategoryFilterScreen({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Choose category',
    children: [
      for (final category in CategoryConfig.names)
        Card(
          child: ListTile(
            leading: CategoryIcon(category: category, size: 40),
            title: Text(category),
            onTap: () => context.back(category),
          ),
        ),
    ],
  );
}
