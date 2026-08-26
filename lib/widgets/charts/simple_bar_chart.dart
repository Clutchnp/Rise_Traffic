import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class BarDatum {
  final String label;
  final double value;
  final Color color;

  const BarDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// A minimal vertical bar chart built from plain widgets (no external
/// chart package needed).
class SimpleBarChart extends StatelessWidget {
  final List<BarDatum> data;
  final double height;
  final double? maxValue;

  const SimpleBarChart({
    super.key,
    required this.data,
    this.height = 200,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = maxValue ??
        data.map((d) => d.value).fold<double>(0, (p, c) => c > p ? c : p);
    final safeMax = maxVal <= 0 ? 1.0 : maxVal;
    const reservedForLabels = 42.0;
    final barAreaHeight = (height - reservedForLabels).clamp(20.0, double.infinity);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final fraction = (d.value / safeMax).clamp(0.0, 1.0);
          final barHeight = barAreaHeight * fraction;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: d.color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
