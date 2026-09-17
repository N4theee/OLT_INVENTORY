import 'package:flutter/material.dart';

/// Keeps every route and its controls clear of system navigation and cutouts.
/// App bars continue to handle the top status-bar inset themselves.
class AppSafeArea extends StatelessWidget {
  const AppSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(top: false, child: child),
    );
  }
}
