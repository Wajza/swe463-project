import 'package:flutter/material.dart';

/// The layout every screen shares: app bar, content and one main action.
class AppPage extends StatelessWidget {
  const AppPage({
    required this.title,
    this.children,
    this.body,
    this.emptyState,
    this.actions,
    this.action,
    this.floatingActionButton,
    this.showBackButton = true,
    super.key,
  }) : assert(
         (children == null) != (body == null),
         'Provide either children or body',
       );

  final String title;
  final List<Widget>? children;
  final Widget? body;

  /// Shown instead of [children] when there are none.
  final Widget? emptyState;
  final List<Widget>? actions;

  /// The screen's one main button, pinned to the bottom.
  final Widget? action;
  final Widget? floatingActionButton;
  final bool showBackButton;

  Widget _buildContent() {
    if (body != null) return body!;
    if (children!.isEmpty && emptyState != null) return emptyState!;
    return ListView(padding: const EdgeInsets.all(20), children: children!);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, overflow: TextOverflow.ellipsis),
      actions: actions,
      automaticallyImplyLeading: showBackButton,
    ),
    floatingActionButton: floatingActionButton,
    body: _buildContent(),
    bottomNavigationBar: action == null
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: action,
            ),
          ),
  );
}
