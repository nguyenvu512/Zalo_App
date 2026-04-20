import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/auth/screens/forgotPassword_screen.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_bot_screen.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_screen.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/add_contact_screen.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/create_group_info_screen.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/create_group_screen.dart';
import 'package:zalo_mobile_app/features/conversation/screens/add_group_members_screen.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_media_screen.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_setting_screen.dart';
import 'package:zalo_mobile_app/features/conversation/screens/group_member_screen.dart';
import 'package:zalo_mobile_app/features/conversation/screens/search_message_screen.dart';
import 'package:zalo_mobile_app/features/home_screen/screens/home_screen.dart';
import 'package:zalo_mobile_app/features/profile_screen/screens/profile_detail_screen.dart';
import 'package:zalo_mobile_app/features/profile_screen/screens/profile_screen.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(path: AppRoutes.login, builder: (context, state) => LoginScreen()),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(path: AppRoutes.home, builder: (context, state) => HomeScreen()),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileDetail,
      builder: (context, state) {
        final extra = state.extra;

        if (extra == null || extra is! Map) {
          return const Scaffold(
            body: Center(child: Text("Dữ liệu người dùng không hợp lệ")),
          );
        }

        final user = Map<String, dynamic>.from(extra);
        return ProfileDetailScreen(user: user);
      },
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
          type: data?['type'] ?? "",
        );
      },
    ),
    GoRoute(
      path: AppRoutes.conversationSetting,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return ConversationSettingScreen(
          conversationId: data['conversationId'] as String,
          name: data['name'] as String? ?? 'No name',
          avatar: data['avatar'] as String? ?? '',
          type: data['type'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.searchMessage,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return SearchMessageScreen(
          conversationId: data['conversationId'] as String,
          name: data['name'] as String? ?? '',
          avatar: data['avatar'] as String ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.conversationMedia,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return ConversationMediaScreen(
          conversationId: data['conversationId'] as String,
          name: data['name'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.chatbotScreen,
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;

        return ChatBotScreen(
          conversation: {
            "_id": data["conversationId"],
            "name": data["name"],
            "avatarUrl": data["avatar"],
            "type": data["type"],
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addContactScreen,
      builder: (context, state) =>  AddContactScreen(),
    ),
    GoRoute(
      path: AppRoutes.createGroupScreen,
      builder: (context, state) => const CreateGroupScreen(),
    ),
    GoRoute(
      path: AppRoutes.createGroupInfoScreen,
      builder: (context, state) {
        final selectedFriends = state.extra as List<Map<String, dynamic>>;
        return CreateGroupInfoScreen(selectedFriends: selectedFriends);
      },
    ),
    GoRoute(
      path: AppRoutes.groupMembers,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return GroupMembersScreen(
          conversationId: extra['conversationId']?.toString() ?? '',
          groupName: extra['groupName']?.toString() ?? '',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.addGroupMembers,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return AddGroupMembersScreen(
          conversationId: extra['conversationId'] as String,
          groupName: extra['groupName'] as String? ?? 'Nhóm',
          excludeUserIds: List<String>.from(extra['excludeUserIds'] ?? []),
        );
      },
    ),
  ],
);
