import 'package:flutter/material.dart';

class CategoryConfig {
  const CategoryConfig._();

  static const _icons = <String, IconData>{
    'Languages': Icons.translate,
    'Design': Icons.palette_outlined,
    'Technology': Icons.code,
    'Cooking': Icons.restaurant_outlined,
    'Teaching': Icons.school_outlined,
    'Photography': Icons.camera_alt_outlined,
    'Music': Icons.music_note,
    'Repairs': Icons.build_outlined,
    'Business': Icons.business_center_outlined,
    'Fitness': Icons.fitness_center,
  };

  static List<String> get names => _icons.keys.toList();

  static IconData iconFor(String category) =>
      _icons[category] ?? Icons.auto_awesome;
}
