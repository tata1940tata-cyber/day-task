import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/theme/theme_controller.dart';
import '../presentation/today/today_screen.dart';
import 'animation_tokens.dart';
import 'theme.dart';

/// Корневой виджет приложения (ТЗ, разделы 4 и 6).
class DayTaskApp extends ConsumerWidget {
  const DayTaskApp({super.key, this.locale});

  /// Переопределение локали (используется в тестах).
  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp(
      title: 'DayTask',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const <Locale>[Locale('ru'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => AnimatedTheme(
          // A10: плавный переход цветов при смене темы.
          data: Theme.of(context),
          duration: T.theme,
          curve: T.themeCurve,
          child: const TodayScreen(),
        ),
      ),
    );
  }
}
