import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_item.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class ConversationList extends StatefulWidget {
  const ConversationList({super.key});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final ConversationController controller = ConversationController();

  List<dynamic> conversations = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final userId = await storage.read(key: "user_id");
      final data = await controller.getListConversation();

      if (!mounted) return;

      setState(() {
        currentUserId = userId;
        conversations = data ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetchData error: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, dynamic>? getOtherUser(List? members) {
    if (members == null) return null;

    for (final m in members) {
      if (m is! Map<String, dynamic>) continue;

      final user = m["userId"];
      if (user is! Map<String, dynamic>) continue;

      final id = user["_id"];
      if (id == null) continue;

      if (id != currentUserId) {
        return user;
      }
    }

    return null;
  }

  String _getLastMessage(Map<String, dynamic> item) {
    final lastMsg = item["lastMessageId"];
    if (lastMsg == null || lastMsg is! Map) {
      return "Bắt đầu cuộc trò chuyện";
    }

    if (lastMsg["isRecalled"] == true) return "Tin nhắn đã bị thu hồi";
    if (lastMsg["isDeleted"] == true) return "Tin nhắn đã bị xóa";

    final type = lastMsg["type"] ?? "text";

    switch (type) {
      case "text":
        return (lastMsg["content"] ?? "").toString();
      case "image":
        return "📷 Hình ảnh";
      case "file":
        return "📎 Tệp đính kèm";
      default:
        return "Tin nhắn mới";
    }
  }

  String _getLastTime(Map<String, dynamic> item) {
    final lastMsg = item["lastMessageId"];
    if (lastMsg == null || lastMsg is! Map) return "";

    final raw = lastMsg["createdAt"];
    if (raw == null) return "";

    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final now = DateTime.now();

      final isToday =
          dt.day == now.day && dt.month == now.month && dt.year == now.year;

      if (isToday) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }

      return "${dt.day}/${dt.month}";
    } catch (e) {
      return "";
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 180),
        Center(
          child: Text(
            "Không có cuộc trò chuyện",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationList() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = conversations[index];

        if (item is! Map<String, dynamic>) {
          return const SizedBox.shrink();
        }

        final members = item["members"];
        final otherUser = getOtherUser(members);

        if (otherUser == null) {
          return const SizedBox.shrink();
        }

        final name = (otherUser["fullName"] ?? "No name").toString();
        final avatar = (otherUser["avatarUrl"] ?? "").toString();
        final conversationId = (item["_id"] ?? "").toString();
        final otherUserId = (otherUser["_id"] ?? "").toString();

        return ConversationItem(
          name: name,
          avatarUrl: avatar,
          lastMessage: _getLastMessage(item),
          time: _getLastTime(item),
          unreadCount: 0,
          onTap: () async {
            await context.push(
              AppRoutes.chatScreen,
              extra: {
                "conversationId": conversationId,
                "otherUserId": otherUserId,
                "name": name,
                "avatar": avatar,
              },
            );

            await fetchData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: conversations.isEmpty ? _buildEmptyState() : _buildConversationList(),
    );
  }
}