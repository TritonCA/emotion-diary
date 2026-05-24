import 'package:flutter/material.dart';

/// Resolves the domain's logical `iconName` to a Material icon, matching the
/// Material Symbols used in the HTML mockups. Lives in core (presentation
/// helper) so the domain stays Flutter-free.
class EmotionIcons {
  const EmotionIcons._();

  static IconData forCategory(String iconName) => switch (iconName) {
        'joy' => Icons.sentiment_very_satisfied,
        'calm' => Icons.self_improvement,
        'love' => Icons.favorite_border,
        'interest' => Icons.lightbulb_outline,
        'sadness' => Icons.sentiment_dissatisfied,
        'anger' => Icons.sentiment_very_dissatisfied,
        'fear' => Icons.warning_amber_rounded,
        'surprise' => Icons.auto_awesome,
        'tiredness' => Icons.bedtime_outlined,
        _ => Icons.sentiment_neutral,
      };
}
