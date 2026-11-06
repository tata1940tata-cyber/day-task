import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/animation_tokens.dart';
import '../../app/strings.dart';
import '../../domain/task.dart';
import '../theme/theme_controller.dart';
import 'today_controller.dart';
import 'widgets/add_task_bar.dart';
import 'widgets/delete_confirm_sheet.dart';
import 'widgets/empty_state.dart';
import 'widgets/skeleton.dart';
import 'widgets/task_list_view.dart';

/// Единственный экран MVP: «Сегодня» (ТЗ, раздел 4).
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Смена дня при возвращении на экран (FR-01, S3).
    if (state == AppLifecycleState.resumed) {
      ref.read(todayControllerProvider.notifier).refreshIfDayChanged();
    }
  }

  void _showUndoSnackbar(Task task) {
    final strings = Strings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.taskDeleted),
        duration: T.undoWindow,
        action: SnackBarAction(
          label: strings.undo,
          onPressed: () =>
              ref.read(todayControllerProvider.notifier).undoDelete(task),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final confirmed =
        await showDeleteConfirmSheet(context, Strings.of(context));
    if (!confirmed || !mounted) return;
    await ref.read(todayControllerProvider.notifier).deleteTask(task);
    if (!mounted) return;
    _showUndoSnackbar(task);
  }

  Future<AddTaskError?> _submitTask(String text) =>
      ref.read(todayControllerProvider.notifier).addTask(text);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayControllerProvider);
    final strings = Strings.of(context);
    final themeMode = ref.watch(themeControllerProvider);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    ref.listen<String?>(
      todayControllerProvider.select((s) => s.errorMessage),
      (previous, next) {
        if (next == null) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(strings.storageError)));
        ref.read(todayControllerProvider.notifier).clearError();
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state, strings, themeMode),
            Expanded(child: _buildBody(state, strings, reducedMotion)),
            AddTaskBar(
              strings: strings,
              reducedMotion: reducedMotion,
              onSubmit: _submitTask,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    TodayState state,
    Strings strings,
    ThemeMode themeMode,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.todayWord,
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  strings.headerDate(state.today),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  strings.doneCounter(state.todayDoneCount, state.todayTotal),
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('theme_toggle'),
            tooltip: strings.themeTooltip(themeMode),
            onPressed: () => ref.read(themeControllerProvider.notifier).cycle(),
            icon: Icon(switch (themeMode) {
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
              ThemeMode.system => Icons.brightness_auto_outlined,
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TodayState state, Strings strings, bool reducedMotion) {
    switch (state.status) {
      case TodayStatus.loading:
        return const TaskListSkeleton();
      case TodayStatus.error:
        return MessageView(
          message: strings.loadError,
          retryLabel: strings.retry,
          onRetry: () => ref.read(todayControllerProvider.notifier).retry(),
        );
      case TodayStatus.ready:
        final tasks = state.todayTasks;
        if (tasks.isEmpty) {
          return EmptyState(title: strings.emptyTitle, hint: strings.emptyHint);
        }
        return TaskListView(
          tasks: tasks,
          strings: strings,
          reducedMotion: reducedMotion,
          onToggle: (task) =>
              ref.read(todayControllerProvider.notifier).toggleTask(task),
          onDelete: (task) {
            ref.read(todayControllerProvider.notifier).deleteTask(task);
            _showUndoSnackbar(task);
          },
          onDeleteRequested: _confirmDelete,
        );
    }
  }
}
