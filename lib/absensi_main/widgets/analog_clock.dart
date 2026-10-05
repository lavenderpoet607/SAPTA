import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  final double size;
  final Color dialColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color centerPointColor;
  final bool showTicks;
  final bool showSeconds;

  const AnalogClock({
    super.key,
    this.size = 52.0,
    this.dialColor = Colors.transparent,
    this.hourHandColor = Colors.white,
    this.minuteHandColor = Colors.white,
    this.secondHandColor = const Color(0xFFFBBF24), // Aksen amber
    this.centerPointColor = Colors.white,
    this.showTicks = true,
    this.showSeconds = true,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late DateTime _dateTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _dateTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _dateTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _AnalogClockPainter(
            dateTime: _dateTime,
            dialColor: widget.dialColor,
            hourHandColor: widget.hourHandColor,
            minuteHandColor: widget.minuteHandColor,
            secondHandColor: widget.secondHandColor,
            centerPointColor: widget.centerPointColor,
            showTicks: widget.showTicks,
            showSeconds: widget.showSeconds,
          ),
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime dateTime;
  final Color dialColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color centerPointColor;
  final bool showTicks;
  final bool showSeconds;

  _AnalogClockPainter({
    required this.dateTime,
    required this.dialColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    required this.centerPointColor,
    required this.showTicks,
    required this.showSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (dialColor != Colors.transparent) {
      final dialPaint = Paint()
        ..color = dialColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, dialPaint);
    }

    if (showTicks) {
      final tickPaint = Paint()
        ..color = hourHandColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      for (int i = 0; i < 12; i++) {
        final angle = i * (2 * math.pi / 12);
        final dotRadius = (i % 3 == 0) ? 1.5 : 0.9;
        final x = center.dx + (radius * 0.82) * math.cos(angle);
        final y = center.dy + (radius * 0.82) * math.sin(angle);
        canvas.drawCircle(Offset(x, y), dotRadius, tickPaint);
      }
    }

    final hour = dateTime.hour % 12;
    final minute = dateTime.minute;
    final second = dateTime.second;

    final hourAngle =
        (hour + minute / 60.0 + second / 3600.0) * (2 * math.pi / 12) -
        (math.pi / 2);
    final hourHandLength = radius * 0.50;
    final hourPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = math.max(2.2, radius * 0.09)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(
        center.dx + hourHandLength * math.cos(hourAngle),
        center.dy + hourHandLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    final minuteAngle =
        (minute + second / 60.0) * (2 * math.pi / 60) - (math.pi / 2);
    final minuteHandLength = radius * 0.72;
    final minutePaint = Paint()
      ..color = minuteHandColor.withValues(alpha: 0.95)
      ..strokeWidth = math.max(1.5, radius * 0.06)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteHandLength * math.cos(minuteAngle),
        center.dy + minuteHandLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    if (showSeconds) {
      final secondAngle = second * (2 * math.pi / 60) - (math.pi / 2);
      final secondHandLength = radius * 0.82;
      final secondHandTail = radius * 0.18;
      final secondPaint = Paint()
        ..color = secondHandColor
        ..strokeWidth = math.max(1.0, radius * 0.035)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(
          center.dx - secondHandTail * math.cos(secondAngle),
          center.dy - secondHandTail * math.sin(secondAngle),
        ),
        Offset(
          center.dx + secondHandLength * math.cos(secondAngle),
          center.dy + secondHandLength * math.sin(secondAngle),
        ),
        secondPaint,
      );

      final secondDotPaint = Paint()
        ..color = secondHandColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, math.max(2.0, radius * 0.08), secondDotPaint);
    }

    final centerPointPaint = Paint()
      ..color = centerPointColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, math.max(1.2, radius * 0.05), centerPointPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.dateTime.second != dateTime.second ||
        oldDelegate.dateTime.minute != dateTime.minute ||
        oldDelegate.dateTime.hour != dateTime.hour;
  }
}
