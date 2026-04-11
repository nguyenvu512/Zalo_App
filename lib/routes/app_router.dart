import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_screen.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/add_contact_screen.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/contact_screen.dart';
import 'package:zalo_mobile_app/features/home_screen/screens/home_screen.dart';
import 'package:zalo_mobile_app/features/profile_screen/screens/profile_screen.dart';
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
    GoRoute(
      path: AppRoutes.chatScreen,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>?;

        return ChatScreen(
          conversationId: data?['conversationId'] ?? "",
          otherUserId: data?['otherUserId'] ?? "",
          name: data?['name'] ?? "No name",
          avatar: data?['avatar'] ?? "",
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addContactScreen,
      builder: (context, state) => AddContactScreen(),
    ),
  ],
);