import 'package:flutter/material.dart';
import '../../../entries/domain/entities/emotion.dart';
import '../../../entries/domain/entities/emotion_category.dart';

/// Pulsing concentric circles whose size, speed and color react to the
/// intensity + dominant valence — a direct port of the HTML `updateVizStyles`.
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

  List<Color> _palette() {
    final v = widget.intensity;
    final dom = _dominant();
    if (v <= 3) {
      return const [Color(0xFFFFFFFF), Color(0xFFE9DDFF), Color(0xFFF5F5F5)];
    }
    if (v >= 7 && dom == Valence.positive) {
      return const [Color(0xFF10B981), Color(0xFF059669), Color(0xFF34D399)];
    }
    if (v >= 7 && dom == Valence.negative) {
      return const [Color(0xFFEF4444), Color(0xFF991B1B), Color(0xFFDC2626)];
    }
    return const [Color(0xFF8B8BF0), Color(0xFF6750A4), Color(0xFFCFBCFF)];
  }

  @override
  Widget build(BuildContext context) {
    final base = 40.0 + widget.intensity * 12.0;
    final sizes = [base + 70, base + 30, base]; // back -> front
    final colors = _palette();
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
                _circle(sizes[i], colors[2 - i], 0.3 + 0.3 * t,
                    0.95 + 0.10 * t),
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
