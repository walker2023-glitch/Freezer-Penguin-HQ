// Shared BentoCard container widget — extracted from main.dart (Phase 5)
// so lib/screens/consume_screen.dart can import it without a circular dep.

import 'package:flutter/material.dart';

import '../config.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.outline, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
