import 'package:flutter/material.dart';
import 'package:olt_inventory/constants/app_constants.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

int responsiveGridCount(BuildContext context, {int maxColumns = 5}) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1100) return maxColumns.clamp(2, 5);
  if (width >= 800) return 3;
  if (width >= 500) return 2;
  return 2;
}

double responsivePadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 800) return 24;
  return 16;
}
