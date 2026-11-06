import 'package:flutter/material.dart';

import '../../../app/animation_tokens.dart';
import '../../../app/strings.dart';
import '../../../domain/task.dart';
import 'strikethrough_text.dart';
import 'task_checkbox.dart';

/// Карточка задачи: отметка, свайп влево для удаления (A6/A7),
/// долгое нажатие — подтверждение удаления (A11).
class TaskTile extends StatefulWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.strings,
    required this.reducedMotion,
    required this.onToggle,
    required this.onDelete,
    required this.onDeleteRequested,
  });

  final Task task;
  final Strings strings;
  final bool reducedMotion;

  /// Тап по чекбоксу или строке — переключить статус (FR-03).
  final ValueChanged<Task> onToggle;

  /// Свайп завершён — задача удаляется (FR-04).
  final ValueChanged<Task> onDelete;

  /// Долгое нажатие — открыть подтверждение удаления (FR-04).
  final ValueChanged<Task> onDeleteRequested;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this);

  double _dragFraction = 0.0;
  double _from = 0.0;
  double _to = 0.0;
  double _width = 1.0;
  bool _dragging = false;
  bool _dismissing = false;
  bool _deleteNotified = false;
  Curve _curve = T.settleBackCurve;

  /// Текущий визуальный прогресс сдвига (0..1) с учётом «отскока» (A7).
  double get _progress {
    if (_controller.isAnimating) {
      final t = _curve.transform(_controller.value);
      final raw = _from + (_to - _from) * t;
      final overshoot = T.maxOvershootPx / _width;
      return raw.clamp(-overshoot, 1.0);
    }
    return _dragFraction;
  }

  void _handleDragStart(DragStartDetails details) {
    _dragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_deleteNotified) return;
    setState(() {
      _controller.stop();
      // Свайп влево — отрицательная дельта: вычитаем, чтобы прогресс рос.
      _dragFraction =
          (_dragFraction - (details.primaryDelta ?? 0) / _width).clamp(0.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    _settle(dismiss: _dragFraction >= 0.5);
  }

  /// Свайп прерван. Отказ распознавателя без движения (например, при тапе)
  /// не должен запускать анимацию — иначе тап «съедается» guard'ом ниже.
  void _handleDragCancel() {
    if (!_dragging) return;
    _dragging = false;
    _settle(dismiss: false);
  }

  void _settle({required bool dismiss}) {
    _from = _dragFraction;
    _to = dismiss ? 1.0 : 0.0;
    _dismissing = dismiss;
    _curve = dismiss ? T.dismissCurve : T.settleBackCurve;

    if (widget.reducedMotion) {
      setState(() => _dragFraction = _to);
      if (dismiss) _notifyDeleted();
      return;
    }

    _controller.duration = dismiss ? T.dismiss : T.settleBack;
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _dragFraction = _to);
      if (dismiss) _notifyDeleted();
    });
    setState(() {});
  }

  void _notifyDeleted() {
    if (_deleteNotified) return;
    _deleteNotified = true;
    widget.onDelete(widget.task);
  }

  void _handleToggle() {
    if (_deleteNotified || _controller.isAnimating) return;
    widget.onToggle(widget.task);
  }

  void _handleLongPress() {
    if (_deleteNotified) return;
    widget.onDeleteRequested(widget.task);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width.isFinite && width > 0) _width = width;

        final progress = _progress;
        final collapse = _dismissing ? progress : 0.0;
        return Opacity(
          opacity: (1.0 - collapse * 1.2).clamp(0.0, 1.0),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: (1.0 - collapse).clamp(0.0, 1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBackground(scheme)),
                  FractionalTranslation(
                    translation: Offset(-progress, 0),
                    child: _buildCard(context, scheme),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }

  Widget _buildCard(BuildContext context, ColorScheme scheme) {
    final task = widget.task;
    final strings = widget.strings;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _handleDragCancel,
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _handleToggle,
          onLongPress: _handleLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Чекбокс — чисто визуальный: тап обрабатывает InkWell,
                // чтобы не было двойного переключения (FR-03).
                TaskCheckbox(
                  value: task.isCompleted,
                  onChanged: null,
                  reducedMotion: widget.reducedMotion,
                  semanticLabel: strings.checkboxLabel,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    label: strings.taskSemantics(task.title, task.isCompleted),
                    child: StrikethroughText(
                      text: task.title,
                      struck: task.isCompleted,
                      reducedMotion: widget.reducedMotion,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
