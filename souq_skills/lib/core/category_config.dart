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

  static const _skills = <String, List<String>>{
    'Languages': ['English tutoring', 'Arabic', 'French', 'Spanish'],
    'Design': ['UI design', 'Figma', 'Arabic calligraphy', 'Drawing'],
    'Technology': ['Flutter', 'Website building', 'Python', 'Excel'],
    'Cooking': ['Saudi cooking', 'Baking', 'Nutrition', 'Coffee making'],
    'Teaching': ['Math tutoring', 'Science tutoring', 'Exam preparation'],
    'Photography': ['Photography', 'Photo editing', 'Video editing'],
    'Music': ['Oud lessons', 'Piano', 'Singing', 'Instrument repair'],
    'Repairs': ['Phone repair', 'Car care', 'Home repairs'],
    'Business': ['Bookkeeping', 'Social media', 'Marketing'],
    'Fitness': ['Fitness coaching', 'Yoga', 'Swimming'],
  };

  static List<String> get names => _icons.keys.toList();

  static IconData iconFor(String category) =>
      _icons[category] ?? Icons.auto_awesome;

  static List<String> skillsFor(String category) =>
      _skills[category] ?? const [];

  static List<String> get allSkills =>
      _skills.values.expand((skills) => skills).toList()..sort();
}
