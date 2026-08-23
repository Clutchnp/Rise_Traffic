import 'package:flutter/material.dart';
import 'package:frontend/core/app_theme.dart';

class CongestionChart extends StatefulWidget {
  const CongestionChart({super.key});

  @override
  State<CongestionChart> createState() => _CongestionChartState();
}

class _CongestionChartState extends State<CongestionChart> {
  int? selectedIndex;

  static const List<double> hourlyCongestion = [
    12.0, 8.0, 5.0, 7.0, 15.0, 32.0, 68.0, 88.0, 94.0, 82.0, 64.0, 58.0,
    62.0, 59.0, 65.0, 78.0, 91.0, 96.0, 89.0, 74.0, 55.0, 41.0, 28.0, 18.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Congestion Trend',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Traffic intensity over 24 hours',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Badge(
                    label: 'Peak: 96%',
                    color: AppColors.trafficCritical,
                  ),
                  _Badge(
                    label: 'Avg: 53%',
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _CongestionChartPainter(
                data: hourlyCongestion,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                return const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('00:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text('12:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                    Text('23:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  ],
                );
              }
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('00:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('06:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('12:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('18:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                  Text('23:00', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CongestionChartPainter extends CustomPainter {
  final List<double> data;
  final int? selectedIndex;

  _CongestionChartPainter({
    required this.data,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines
    const gridSteps = 4;
    for (int i = 0; i <= gridSteps; i++) {
      final y = (size.height / gridSteps) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = size.width / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / 100.0 * size.height);
      points.add(Offset(x, y));
    }

    // Path for line
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill under path
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line paint
    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Draw peak point highlight
    final peakIndex = data.indexOf(data.reduce((a, b) => a > b ? a : b));
    final peakPoint = points[peakIndex];

    final peakGlowPaint = Paint()
      ..color = AppColors.trafficCritical.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(peakPoint, 8, peakGlowPaint);

    final peakDotPaint = Paint()
      ..color = AppColors.trafficCritical
      ..style = PaintingStyle.fill;
    canvas.drawCircle(peakPoint, 4, peakDotPaint);
  }

  @override
  bool shouldRepaint(covariant _CongestionChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedIndex != selectedIndex;
  }
}
