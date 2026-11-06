import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/animation_tokens.dart';
import '../../../app/strings.dart';
import '../../../domain/task_validation.dart';
import '../today_controller.dart';

/// Поле ввода и кнопка добавления задачи (ТЗ, FR-02; анимация ошибки — A12).
class AddTaskBar extends StatefulWidget {
  const AddTaskBar({
    super.key,
    required this.strings,
    required this.reducedMotion,
    required this.onSubmit,
  });

  final Strings strings;
  final bool reducedMotion;

  /// Возвращает ошибку добавления или `null` при успехе.
  final Future<AddTaskError?> Function(String text) onSubmit;

  @override
  State<AddTaskBar> createState() => _AddTaskBarState();
}

class _AddTaskBarState extends State<AddTaskBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: T.duration(T.shake, reducedMotion: widget.reducedMotion),
  );

  String? _hint;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final atLimit = _textController.text.characters.length >=
        TitleValidation.maxTitleLength;
    if (atLimit && _hint == null) {
      setState(() => _hint = widget.strings.maxLengthError);
    } else if (!atLimit && _hint == widget.strings.maxLengthError) {
      setState(() => _hint = null);
    }
  }

  Future<void> _submit() async {
    final error = await widget.onSubmit(_textController.text);
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _textController.clear();
        _hint = null;
      });
      // Серийное добавление: клавиатура остаётся открытой (FR-02, S1).
      _focusNode.requestFocus();
      return;
    }
    setState(() => _hint = _hintFor(error));
    if (!widget.reducedMotion) {
      await _shake.forward(from: 0);
    }
  }

  String _hintFor(AddTaskError error) {
    switch (error) {
      case AddTaskError.empty:
        return widget.strings.emptyInputError;
      case AddTaskError.tooLong:
        return widget.strings.maxLengthError;
      case AddTaskError.limitReached:
        return widget.strings.limitError;
      case AddTaskError.storage:
        return widget.strings.storageError;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              // A12: ±6 px, 2 цикла, затухание.
              final dx = math.sin(t * math.pi * 2 * 2) * 6 * (1 - t);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('add_task_field'),
                    controller: _textController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    maxLength: TitleValidation.maxTitleLength,
                    decoration: InputDecoration(
                      hintText: widget.strings.inputHint,
                      counterText: '',
                      filled: true,
                      fillColor:
                          scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  key: const Key('add_task_button'),
                  tooltip: widget.strings.addTooltip,
                  onPressed: _submit,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (_hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _hint!,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
