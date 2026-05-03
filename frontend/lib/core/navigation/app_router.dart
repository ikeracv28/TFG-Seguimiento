import 'package:go_router/go_router.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/panel_tutor_empresa_screen.dart';
import '../../presentation/screens/panel_tutor_centro_screen.dart';
import '../../presentation/screens/panel_admin_screen.dart';

GoRouter buildRouter(AuthProvider auth) => GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final goingToLogin = state.matchedLocation == '/login';

        if (!loggedIn) return goingToLogin ? null : '/login';
        if (goingToLogin) return _homeForRoles(auth.user!.roles);

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/tutor-empresa',
          builder: (_, __) => const PanelTutorEmpresaScreen(),
        ),
        GoRoute(
          path: '/tutor-centro',
          builder: (_, __) => const PanelTutorCentroScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const PanelAdminScreen(),
        ),
      ],
    );

String _homeForRoles(List<String> roles) {
  if (roles.contains('ROLE_ADMIN')) return '/admin';
  if (roles.contains('ROLE_TUTOR_EMPRESA')) return '/tutor-empresa';
  if (roles.contains('ROLE_TUTOR_CENTRO')) return '/tutor-centro';
  return '/dashboard';
}
