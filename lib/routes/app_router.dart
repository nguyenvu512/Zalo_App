import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/home/screens/home_screen.dart';
import 'package:zalo_mobile_app/features/profile/screens/profile_screen.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => ProfileScreen(),
    ),
  ],
);