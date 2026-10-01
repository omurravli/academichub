import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:studiq/core/navigation/navigator_key.dart';
import 'package:studiq/features/auth/presentation/providers/auth_provider.dart';
import 'package:studiq/features/auth/presentation/screens/login_screen.dart';
import 'package:studiq/features/auth/presentation/screens/signup_screen.dart';
import 'package:studiq/features/splash/presentation/screens/splash_screen.dart';
import 'package:studiq/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:studiq/features/today/presentation/screens/today_screen.dart';
import 'package:studiq/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:studiq/features/planner/presentation/screens/planner_screen.dart';
import 'package:studiq/features/planner/presentation/screens/planner_item_detail_screen.dart';
import 'package:studiq/features/planner/presentation/screens/add_edit_planner_item_screen.dart';
import 'package:studiq/features/timer/presentation/screens/timer_screen.dart';
import 'package:studiq/features/projects/presentation/screens/projects_screen.dart';
import 'package:studiq/features/projects/presentation/screens/project_detail_screen.dart';
import 'package:studiq/features/projects/presentation/screens/add_edit_project_screen.dart';
import 'package:studiq/features/settings/presentation/screens/settings_screen.dart';
import 'package:studiq/features/settings/presentation/screens/deleted_plans_screen.dart';
import 'package:studiq/features/settings/presentation/screens/deleted_projects_screen.dart';
import 'package:studiq/features/stats/presentation/screens/focus_stats_screen.dart';
import 'package:studiq/app/widgets/main_shell.dart';

abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const today = '/today';
  static const calendar = '/calendar';
  static const planner = '/planner';
  static const addPlannerItem = '/planner/add';
  static const focus = '/focus';
  static const projects = '/projects';
  static const addProject = '/projects/add';
  static const settings = '/settings';
  static const deletedPlans = '/settings/deleted-plans';
  static const deletedProjects = '/settings/deleted-projects';
  static const focusStats = '/settings/focus-report';

  static const _public = {splash, onboarding, login, signup};
  static bool isPublic(String loc) => _public.contains(loc);
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
  }
}

CustomTransitionPage<void> _slidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        )),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/') return AppRoutes.splash;

      final authState = ref.read(authStateProvider);
      if (authState.isLoading) return null;

      final isLoggedIn =
          authState.maybeWhen(data: (u) => u != null, orElse: () => false);

      if (!isLoggedIn && !AppRoutes.isPublic(loc)) return AppRoutes.login;
      if (isLoggedIn && (loc == AppRoutes.login || loc == AppRoutes.signup)) {
        return AppRoutes.today;
      }
      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) =>
            _slidePage(const SplashScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _slidePage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _slidePage(const LoginScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.signup,
        pageBuilder: (context, state) =>
            _slidePage(const SignupScreen(), state),
      ),

      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          child: MainShell(child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.today,
            pageBuilder: (context, state) =>
                _slidePage(const TodayScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) =>
                _slidePage(const CalendarScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.planner,
            pageBuilder: (context, state) =>
                _slidePage(const PlannerScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.focus,
            pageBuilder: (context, state) =>
                _slidePage(const TimerScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.projects,
            pageBuilder: (context, state) =>
                _slidePage(const ProjectsScreen(), state),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                _slidePage(const SettingsScreen(), state),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.addPlannerItem,
        pageBuilder: (context, state) =>
            _slidePage(const AddEditPlannerItemScreen(), state),
      ),
      GoRoute(
        path: '/planner/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final isEdit = state.uri.queryParameters['edit'] == 'true';
          if (isEdit) {
            return _slidePage(AddEditPlannerItemScreen(itemId: id), state);
          }
          return _slidePage(PlannerItemDetailScreen(itemId: id), state);
        },
      ),
      GoRoute(
        path: AppRoutes.addProject,
        pageBuilder: (context, state) =>
            _slidePage(const AddEditProjectScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.deletedPlans,
        pageBuilder: (context, state) =>
            _slidePage(const DeletedPlansScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.deletedProjects,
        pageBuilder: (context, state) =>
            _slidePage(const DeletedProjectsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.focusStats,
        pageBuilder: (context, state) =>
            _slidePage(const FocusStatsScreen(), state),
      ),
      GoRoute(
        path: '/projects/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final isEdit = state.uri.queryParameters['edit'] == 'true';
          if (isEdit) {
            return _slidePage(AddEditProjectScreen(projectId: id), state);
          }
          return _slidePage(ProjectDetailScreen(projectId: id), state);
        },
      ),
    ],
  );
});
