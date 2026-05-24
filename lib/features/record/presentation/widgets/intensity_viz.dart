import 'package:flutter/material.dart';
import '../../../entries/domain/entities/emotion.dart';
import '../../../entries/domain/entities/emotion_category.dart';

/// Pulsing concentric circles whose size, speed and color react to the
/// intensity + dominant valence. Color is interpolated continuously across
/// the 0..10 range (no sharp "always purple at 5" jump).
class IntensityViz extends StatefulWidget {
  const IntensityViz({super.key, required this.intensity, required this.selected});
  final int intensity;
  final List<Emotion> selected;

  @override
  State<IntensityViz> createState() => _IntensityVizState();
}

class _IntensityVizState extends State<IntensityViz>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant IntensityViz old) {
    super.didUpdateWidget(old);
    final speedMs = (4.0 - widget.intensity * 0.3).clamp(1.0, 4.0) * 1000;
    final dur = Duration(milliseconds: speedMs.round());
    if (_ctrl.duration != dur) {
      _ctrl.duration = dur;
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Valence _dominant() {
    if (widget.selected.isEmpty) return Valence.neutral;
    var pos = 0, neg = 0;
    for (final e in widget.selected) {
      if (e.valence == Valence.positive) pos++;
      if (e.valence == Valence.negative) neg++;
    }
    if (pos > neg) return Valence.positive;
    if (neg > pos) return Valence.negative;
    return Valence.neutral;
  }

  /// HSL-driven palette: hue is locked to the dominant valence; saturation
  /// and lightness scale with intensity so 0 looks airy/pale and 10 looks
  /// deep/saturated. Returns three tones for the concentric circles
  /// (back -> mid -> front).
  List<Color> _palette(BuildContext context) {
    final t = (widget.intensity / 10.0).clamp(0.0, 1.0);
    final dom = _dominant();

    // Hue per valence. Neutral picks up the current theme accent so the
    // visualization stays consistent with the user's color choice.
    final double hue = switch (dom) {
      Valence.positive => 152, // emerald
      Valence.negative => 6,   // warm red-orange
      Valence.neutral => HSLColor.fromColor(Theme.of(context).colorScheme.primary).hue,
    };

    // Smooth curves — at v=0 the circle is almost the surface tint, at v=10
    // it's a rich, saturated tone of the chosen hue.
    final sat = (0.20 + 0.65 * t).clamp(0.0, 1.0);
    final light = (0.85 - 0.35 * t).clamp(0.0, 1.0);

    Color tone(double dl, double ds) => HSLColor.fromAHSL(
          1,
          hue,
          (sat + ds).clamp(0.05, 1.0),
          (light + dl).clamp(0.0, 1.0),
        ).toColor();

    return [
      tone(-0.12, 0.05), // back — darkest
      tone(0.0, 0.0),    // mid
      tone(0.10, -0.05), // front — lightest
    ];
  }

  @override
  Widget build(BuildContext context) {
    final base = 40.0 + widget.intensity * 12.0;
    final sizes = [base + 70, base + 30, base]; // back -> front
    final colors = _palette(context);
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                _circle(sizes[i], colors[i], 0.3 + 0.3 * t, 0.95 + 0.10 * t),
            ],
          );
        },
      ),
    );
  }

  Widget _circle(double size, Color color, double opacity, double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
