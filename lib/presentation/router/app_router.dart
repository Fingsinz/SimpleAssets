import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../analysis/analysis_page.dart';
import '../common/app_shell.dart';
import '../holding/add_holding_page.dart';
import '../holding/holding_detail_page.dart';
import '../holding/holding_list_page.dart';
import '../overview/overview_page.dart';
import '../settings/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/overview',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/overview',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: OverviewPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/holdings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HoldingListPage(),
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddHoldingPage(),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    if (id == null) {
                      return const _NotFoundPage();
                    }
                    return HoldingDetailPage(holdingId: id);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final id =
                            int.tryParse(state.pathParameters['id'] ?? '');
                        if (id == null) {
                          return const _NotFoundPage();
                        }
                        return AddHoldingPage(holdingId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analysis',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AnalysisPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => _NotFoundPage(
    message: state.error?.toString(),
  ),
);

class _NotFoundPage extends StatelessWidget {
  final String? message;

  const _NotFoundPage({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message ?? '未找到该页面',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
