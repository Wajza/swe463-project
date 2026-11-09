import 'package:flutter/material.dart';

class SearchField extends StatelessWidget {
  const SearchField({required this.onSubmitted, this.controller, super.key});

  final ValueChanged<String> onSubmitted;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    textInputAction: TextInputAction.search,
    onSubmitted: onSubmitted,
    decoration: const InputDecoration(
      hintText: 'Search for a skill',
      prefixIcon: Icon(Icons.search),
    ),
  );
}
