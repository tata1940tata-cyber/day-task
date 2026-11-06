import 'dart:math';

import 'package:flutter/material.dart';

import '../../../app/animation_tokens.dart';
import '../../../app/strings.dart';
import '../../../domain/task.dart';
import 'task_tile.dart';

/// Список задач с анимациями появления, перемещения и удаления
/// (ТЗ, FR-06: A1, A4, A5, A6, A8, A9).
///
/// Одна секция «невыполненных» сверху и, при наличии, заголовок
/// «Выполненные (X)» снизу (ТЗ, FR-01).
class TaskListView extends StatefulWidget {
  const TaskListView({
    super.key,
    required this.tasks,
    required this.strings,
    required this.reducedMotion,
    required this.onToggle,
    required this.onDelete,
    required this.onDeleteRequested,
  });

  final List<Task> tasks;
  final Strings strings;
  final bool reducedMotion;
  final ValueChanged<Task> onToggle;
  final ValueChanged<Task> onDelete;
  final ValueChanged<Task> onDeleteRequested;

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _Row {
  const _Row(this.id, {this.task, this.doneCount});

  final String id;
  final Task? task;
  final int? doneCount;

  bool get isHeader => task == null;
}

class _TaskListViewState extends State<TaskListView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<_Row> _rows = _buildRows(widget.tasks);

  /// Идентификаторы задач, удаляемых свайпом: их строка схлопывается самой
  /// карточкой и исчезает мгновенно (без повторной анимации).
  final Set<String> _instantExit = <String>{};

  /// A9: каскадное появление только при первом показе списка.
  bool _stagger = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _stagger = false);
    });
  }

  @override
  void didUpdateWidget(TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcile(_buildRows(widget.tasks));
  }

  List<_Row> _buildRows(List<Task> tasks) {
    final rows = <_Row>[];
    for (final task in tasks) {
      if (!task.isCompleted) {
        rows.add(_Row('${task.id}|active', task: task));
      }
    }
    final done = tasks.where((task) => task.isCompleted).toList();
    if (done.isNotEmpty) {
      rows.add(_Row('header-done', doneCount: done.length));
      for (final task in done) {
        rows.add(_Row('${task.id}|done', task: task));
      }
    }
    return rows;
  }

  /// Синхронизация с AnimatedList: удаления/появления анимируются.
  void _reconcile(List<_Row> newRows) {
    final listState = _listKey.currentState;
    if (listState == null) {
      _rows = newRows;
      return;
    }

    // 1) Удаления — с конца, чтобы индексы оставались корректными.
    for (var i = _rows.length - 1; i >= 0; i--) {
      final row = _rows[i];
      if (newRows.any((candidate) => candidate.id == row.id)) continue;

      _rows.removeAt(i);
      final instant = row.task != null && _instantExit.remove(row.task!.id);
      final isMove = row.task != null &&
          newRows.any((candidate) => candidate.task?.id == row.task!.id);
      final duration = instant
          ? const Duration(milliseconds: 1)
          : (isMove ? T.move : T.appear);

      listState.removeItem(
        i,
        (context, animation) =>
            _buildExiting(row, animation, instant: instant),
        duration:
            T.duration(duration, reducedMotion: widget.reducedMotion),
      );
    }

    // 2) Появления — по порядку следования в новом списке.
    for (var i = 0; i < newRows.length; i++) {
      final row = newRows[i];
      if (_rows.any((candidate) => candidate.id == row.id)) continue;

      _rows.insert(i, row);
      listState.insertItem(
        i,
        duration: T.duration(T.appear, reducedMotion: widget.reducedMotion),
      );
    }

    _rows = newRows;
    _instantExit.clear();
  }

  void _handleSwipeDelete(Task task) {
    _instantExit.add(task.id);
    widget.onDelete(task);
  }

  Widget _buildItem(BuildContext context, int index, Animation<double> animation) {
    final row = _rows[index];
    Widget child =
        row.isHeader ? _buildHeader(row) : _buildTile(row.task!);
    if (_stagger && index < T.staggerMaxItems && !widget.reducedMotion) {
      child = StaggeredAppear(index: index, child: child);
    }
    return SizeTransition(
      sizeFactor: animation,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: animation, curve: T.appearCurve)),
          child: child,
        ),
      ),
    );
  }

  Widget _buildExiting(
    _Row row,
    Animation<double> animation, {
    required bool instant,
  }) {
    if (instant) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: animation,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: animation,
        child: row.isHeader
            ? _buildHeader(row)
            : _buildTile(row.task!, interactive: false),
      ),
    );
  }

  Widget _buildHeader(_Row row) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        widget.strings.doneSection(row.doneCount ?? 0),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildTile(Task task, {bool interactive = true}) {
    return TaskTile(
      key: ValueKey<String>('tile-${task.id}'),
      task: task,
      strings: widget.strings,
      reducedMotion: widget.reducedMotion,
      onToggle: interactive ? widget.onToggle : (task) {},
      onDelete: interactive ? _handleSwipeDelete : (task) {},
      onDeleteRequested: interactive ? widget.onDeleteRequested : (task) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _rows.length,
      itemBuilder: _buildItem,
      padding: const EdgeInsets.only(top: 4, bottom: 12),
    );
  }
}

/// Каскадное появление карточек при первом показе (A9: шаг 30 мс).
class StaggeredAppear extends StatefulWidget {
  const StaggeredAppear({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggeredAppear> createState() => _StaggeredAppearState();
}

class _StaggeredAppearState extends State<StaggeredAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: T.staggerItem +
        T.staggerStep * min(widget.index, T.staggerMaxItems - 1),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = T.staggerCurve.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
