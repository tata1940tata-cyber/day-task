import 'package:flutter/material.dart';

import '../../../app/animation_tokens.dart';

/// Текст с анимированным зачёркиванием: линия прочерчивается слева направо
/// (ТЗ, A3).
class StrikethroughText extends StatelessWidget {
  const StrikethroughText({
    super.key,
    required this.text,
    required this.struck,
    required this.reducedMotion,
    this.style,
    this.maxLines = 2,
  });

  final String text;
  final bool struck;
  final bool reducedMotion;
  final TextStyle? style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveStyle = struck
        ? baseStyle.copyWith(
            color: baseStyle.color?.withValues(alpha: 0.6),
          )
        : baseStyle;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: struck ? 1.0 : 0.0),
      duration: T.duration(T.strikethrough, reducedMotion: reducedMotion),
      curve: T.strikeCurve,
      builder: (context, progress, child) {
        return CustomPaint(
          painter: _StrikethroughPainter(
            text: text,
            style: effectiveStyle,
            maxLines: maxLines,
            progress: progress,
            textScaler: MediaQuery.textScalerOf(context),
          ),
          child: child,
        );
      },
      child: Text(
        text,
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  _StrikethroughPainter({
    required this.text,
    required this.style,
    required this.maxLines,
    required this.progress,
    required this.textScaler,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final double progress;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);

    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );

    final strikeColor = style.color ?? const Color(0xFF000000);
    final paint = Paint()
      ..color = strikeColor
      ..strokeWidth = (style.fontSize ?? 16) * 0.08
      ..strokeCap = StrokeCap.round;

    for (final box in boxes) {
      // Линия прочерчивается слева направо по каждой строке текста (A3).
      final y = box.top + (box.bottom - box.top) * 0.62;
      final width = (box.right - box.left) * progress.clamp(0.0, 1.0);
      canvas.drawLine(
        Offset(box.left, y),
        Offset(box.left + width, y),
        paint,
      );
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.textScaler != textScaler;
}
