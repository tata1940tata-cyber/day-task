import 'package:flutter/material.dart';

import '../../../app/animation_tokens.dart';

/// Анимированный чекбокс: заливка и «прорисовка» галочки (ТЗ, A2).
class TaskCheckbox extends StatefulWidget {
  const TaskCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.reducedMotion,
    required this.semanticLabel,
  });

  final bool value;

  /// Если `null` — чекбокс только визуальный (тап обрабатывает родитель).
  final ValueChanged<bool>? onChanged;
  final bool reducedMotion;
  final String semanticLabel;

  @override
  State<TaskCheckbox> createState() => _TaskCheckboxState();
}

class _TaskCheckboxState extends State<TaskCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: T.duration(T.checkbox, reducedMotion: widget.reducedMotion),
    value: widget.value ? 1.0 : 0.0,
  );

  @override
  void didUpdateWidget(TaskCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    if (widget.reducedMotion) {
      _controller.value = widget.value ? 1.0 : 0.0;
    } else if (widget.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onChanged = widget.onChanged;
    final Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _CheckboxPainter(
          progress: _controller.value,
          scheme: scheme,
        ),
        child: child,
      ),
      child: const SizedBox(width: 44, height: 44),
    );
    return Semantics(
      checked: widget.value,
      label: widget.semanticLabel,
      child: onChanged == null
          ? content
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(!widget.value),
              child: content,
            ),
    );
  }
}

class _CheckboxPainter extends CustomPainter {
  _CheckboxPainter({required this.progress, required this.scheme});

  final double progress;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 24.0;
    final center = size.center(Offset.zero);
    final box = Rect.fromCenter(
      center: center,
      width: boxSize,
      height: boxSize,
    );
    final rrect = RRect.fromRectAndRadius(box, const Radius.circular(7));

    final fill = Color.lerp(scheme.surfaceContainerHighest, scheme.primary,
        Curves.easeInOut.transform(progress.clamp(0.0, 1.0)))!;
    final rPaint = Paint()..color = fill;
    canvas.drawRRect(rrect, rPaint);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Color.lerp(scheme.onSurfaceVariant, scheme.primary,
          progress.clamp(0.0, 1.0))!;
    canvas.drawRRect(rrect, border);

    if (progress <= 0.01) return;

    // Галочка: A -> B -> C, рисуется по мере progress (A2, stroke-draw).
    final a = Offset(box.left + box.width * 0.28, box.top + box.height * 0.52);
    final b = Offset(box.left + box.width * 0.44, box.top + box.height * 0.68);
    final c = Offset(box.left + box.width * 0.72, box.top + box.height * 0.34);
    final first = (b - a).distance;
    final second = (c - b).distance;
    final target = (first + second) * progress.clamp(0.0, 1.0);

    final path = Path()..moveTo(a.dx, a.dy);
    if (target <= first) {
      final t = first == 0 ? 1.0 : target / first;
      path.lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
    } else {
      path.lineTo(b.dx, b.dy);
      final t = second == 0 ? 1.0 : ((target - first) / second).clamp(0.0, 1.0);
      path.lineTo(b.dx + (c.dx - b.dx) * t, b.dy + (c.dy - b.dy) * t);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = scheme.onPrimary,
    );
  }

  @override
  bool shouldRepaint(_CheckboxPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.scheme != scheme;
}
