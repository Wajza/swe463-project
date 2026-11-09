import 'package:flutter/material.dart';

class MenuAction {
  const MenuAction(this.label, this.onSelected);

  final String label;
  final VoidCallback onSelected;
}

/// Holds a screen's less common actions so it keeps one main button.
class OverflowMenu extends StatelessWidget {
  const OverflowMenu({required this.items, super.key});

  final List<MenuAction> items;

  @override
  Widget build(BuildContext context) => PopupMenuButton<MenuAction>(
    tooltip: 'More options',
    onSelected: (item) => item.onSelected(),
    itemBuilder: (_) => [
      for (final item in items)
        PopupMenuItem(value: item, child: Text(item.label)),
    ],
  );
}
