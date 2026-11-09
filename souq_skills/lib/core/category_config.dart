import 'package:flutter/material.dart';

class CategoryConfig {
  const CategoryConfig._();

  static const names = [
    'Languages',
    'Design',
    'Technology',
    'Cooking',
    'Teaching',
    'Photography',
    'Music',
    'Repairs',
    'Business',
    'Fitness',
  ];

  static IconData iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'languages':
        return Icons.translate;
      case 'design':
      case 'art & design':
      case 'creative & design':
        return Icons.palette_outlined;
      case 'technology':
      case 'tech':
        return Icons.code;
      case 'cooking':
      case 'food & home':
        return Icons.restaurant_outlined;
      case 'teaching':
        return Icons.school_outlined;
      case 'photography':
        return Icons.camera_alt_outlined;
      case 'music':
        return Icons.music_note;
      case 'repairs':
        return Icons.build_outlined;
      case 'business':
        return Icons.business_center_outlined;
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.auto_awesome;
    }
  }
}
