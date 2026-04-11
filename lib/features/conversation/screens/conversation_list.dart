import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_item.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  List<dynamic> conversations = [];
  bool isLoading = true;
  String? currentUserId;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final userId = await storage.read(key: "user_id");

      final controller = ConversationController();
      final data = await controller.getListConversation();

      setState(() {
        currentUserId = userId;
        conversations = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 👉 Lấy người còn lại trong chat 1-1
  Map<String, dynamic>? getOtherUser(List members) {
    for (var m in members) {
      if (m["userId"]["_id"] != currentUserId) {
        return m["userId"];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversations.isEmpty) {
      return const Center(child: Text("Không có cuộc trò chuyện"));
    }

    return ListView.separated(
      reverse: true, // 👈 QUAN TRỌNG
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = conversations[index];

        /// 👇 lấy người còn lại
        final otherUser = getOtherUser(item["members"]);

        final name = otherUser?["fullName"] ?? "No name";
        final avatar = otherUser?["avatarUrl"] ?? "";

        return ConversationItem(
          name: name,
          avatarUrl: avatar,
          lastMessage: item["lastMessagePreview"] ?? "",
          time: item["lastMessageAt"] ?? "",
          unreadCount: 0,
          onTap: () {
            context.push(
              AppRoutes.chatScreen,
              extra: {
                "conversationId": item["_id"],
                "otherUserId": otherUser?["_id"],
                "name": name,
                "avatar": avatar,
              },
            );
          },
        );
      },
    );
  }
}