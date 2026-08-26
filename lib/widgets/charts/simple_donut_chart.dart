import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class DonutDatum {
  final String label;
  final double value;
  final Color color;

  const DonutDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// A minimal donut chart with a legend, drawn with a [CustomPainter].
class SimpleDonutChart extends StatelessWidget {
  final List<DonutDatum> data;
  final double size;

  const SimpleDonutChart({super.key, required this.data, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (p, c) => p + c.value);
    final safeTotal = total <= 0 ? 1.0 : total;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _DonutPainter(data: data, total: safeTotal),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: data.map((d) {
              final pct = d.value / safeTotal * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: d.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d.label,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutDatum> data;
  final double total;

  _DonutPainter({required this.data, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;
    double startAngle = -math.pi / 2;

    for (final d in data) {
      final sweep = (d.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = d.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.total != total;
  }
}
