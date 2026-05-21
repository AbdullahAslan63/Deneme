import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/user_entity.dart' show UserRole;
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/join_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/manager_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/resident_dashboard_screen.dart';
import '../../features/expenses/presentation/screens/create_expense_screen.dart';
import '../../features/expenses/presentation/screens/manager_expenses_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/notifications/presentation/screens/send_announcement_screen.dart';
import '../../features/tickets/presentation/screens/create_ticket_screen.dart';
import '../../features/tickets/presentation/screens/manager_tickets_screen.dart';
import '../../features/tickets/presentation/screens/ticket_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth state değişince [GoRouter] redirect’inin yeniden çalışması için gerekli.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    refreshListenable.value++;
  });
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: refreshListenable,
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == '/login' ||
          loc == '/register' ||
          loc == '/join' ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/';

      if (!authState.isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Oturum açıkken login/register/join’de kalma — ana ekrana yönlendir
      if (authState.isAuthenticated &&
          authState.user != null &&
          isAuthRoute &&
          loc != '/') {
        return authState.user!.role == UserRole.manager
            ? '/manager-dashboard'
            : '/resident-dashboard';
      }

      if (authState.isAuthenticated &&
          loc == '/tickets/new' &&
          authState.user?.role == UserRole.manager) {
        return '/manager-dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionDuration: const Duration(milliseconds: 400),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final tween = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/join',
        name: 'join',
        builder: (context, state) {
          return const JoinScreen();
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) {
          return const ForgotPasswordScreen();
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset_password',
        builder: (context, state) {
          // `extra` üzerinden forgot ekranından gelen email taşınır.
          final email = state.extra is String ? state.extra as String : null;
          return ResetPasswordScreen(prefilledEmail: email);
        },
      ),
      GoRoute(
        path: '/manager-dashboard',
        name: 'manager_dashboard',
        builder: (context, state) {
          return const ManagerDashboardScreen();
        },
      ),
      GoRoute(
        path: '/resident-dashboard',
        name: 'resident_dashboard',
        builder: (context, state) {
          return const ResidentDashboardScreen();
        },
      ),
      GoRoute(
        path: '/tickets/new',
        name: 'create_ticket',
        builder: (context, state) => const CreateTicketScreen(),
      ),
      GoRoute(
        path: '/tickets/:ticketId',
        name: 'ticket_detail',
        builder: (context, state) {
          final id = state.pathParameters['ticketId']!;
          return TicketDetailScreen(ticketId: id);
        },
      ),
      GoRoute(
        path: '/manager/tickets',
        name: 'manager_tickets',
        builder: (context, state) => const ManagerTicketsScreen(),
      ),
      GoRoute(
        path: '/manager/expenses',
        name: 'manager_expenses',
        builder: (context, state) => const ManagerExpensesScreen(),
      ),
      GoRoute(
        path: '/expenses/new',
        name: 'create_expense',
        builder: (context, state) {
          final buildingId = state.extra as String? ?? '';
          return CreateExpenseScreen(buildingId: buildingId);
        },
      ),
      GoRoute(
        path: '/manager/announcement',
        name: 'send_announcement',
        builder: (context, state) => const SendAnnouncementScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
