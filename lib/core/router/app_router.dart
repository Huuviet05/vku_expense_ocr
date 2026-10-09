import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/expenses/presentation/screens/home_screen.dart';
import '../../features/expenses/presentation/screens/expense_detail_screen.dart';
import '../../features/expenses/data/models/expense_model.dart';
import '../../features/ocr/data/receipt_parser.dart';
import '../../features/ocr/presentation/screens/ocr_scan_screen.dart';
import '../../features/ocr/presentation/screens/review_receipt_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Named route constants — prevents typo errors
abstract class AppRoutes {
  static const home = '/';
  static const scan = '/scan';
  static const reviewOcr = '/review-ocr';
  static const stats = '/stats';
  static const profile = '/profile';
  static const detail = '/expense/:id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      // ── Shell route: persistent bottom navigation ─────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          // Tab 0: Expense list
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (ctx, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'expense/:id',
                    builder: (ctx, state) {
                      final expense = state.extra as ExpenseModel;
                      return ExpenseDetailScreen(expense: expense);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Tab 1: Statistics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (ctx, _) => const StatsScreen(),
              ),
            ],
          ),
          // Tab 2: Profile & Account
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (ctx, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // ── Full-screen OCR scan route (no bottom nav) ────────────────
      GoRoute(
        path: AppRoutes.scan,
        builder: (ctx, _) => const OcrScanScreen(),
      ),
      // ── Full-screen OCR review & verification route ───────────────
      GoRoute(
        path: AppRoutes.reviewOcr,
        builder: (ctx, state) {
          final result = state.extra as ParsedReceiptResult;
          return ReviewReceiptScreen(initialResult: result);
        },
      ),
    ],
  );
});

// ── Persistent shell with Material 3 NavigationBar ──────────────────────────
class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(
          i,
          initialLocation: i == shell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
