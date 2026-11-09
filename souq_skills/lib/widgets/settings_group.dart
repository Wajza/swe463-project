import 'package:flutter/material.dart';

import 'section_header.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (title != null) SectionHeader(title: title!),
      Card(child: Column(children: children)),
    ],
  );
}
