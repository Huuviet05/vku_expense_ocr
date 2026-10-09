import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ProviderScope wraps the entire app to enable Riverpod state management
    const ProviderScope(child: VkuExpenseApp()),
  );
}

class VkuExpenseApp extends ConsumerWidget {
  const VkuExpenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VKU Expense OCR',
      debugShowCheckedModeBanner: false,
      // ── Material 3 Theme ──────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // ── GoRouter ─────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
