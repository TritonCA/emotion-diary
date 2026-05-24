import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Uppercase tracked section header ("CURRENT EMOTIONS", "DATA", ...).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelCaps(color ?? context.colors.onSurfaceVariant)
          .copyWith(letterSpacing: 1.0),
    );
  }
}
