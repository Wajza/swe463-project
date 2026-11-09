import 'package:flutter/material.dart';

/// A bottom sheet that lets the user pick one option from a list.
abstract final class OptionSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    String Function(T option)? labelOf,
  }) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .6,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(labelOf?.call(option) ?? '$option'),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
          ],
        ),
      ),
    ),
  );
}
