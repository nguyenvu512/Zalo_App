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
  bool isLoading = false;
  String? currentUserId;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading = true;
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
  Map<String, dynamic>? getOtherUser(List? members) {
    if (members == null) return null;

    for (var m in members) {
      if (m == null || m is! Map<String, dynamic>) continue;

      final user = m["userId"];

      // ✅ Kiểm tra chặt hơn: phải là Map và không null
      if (user == null || user is! Map<String, dynamic>) continue;

      final id = user["_id"];
      if (id == null) continue; // ✅ Thêm dòng này

      if (id != currentUserId) {
        return user;
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
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = conversations[index];

        if (item is! Map<String, dynamic>) {
          return const SizedBox();
        }

        final members = item["members"];
        final otherUser = getOtherUser(members);

        // ✅ Bỏ qua nếu không tìm được user
        if (otherUser == null) return const SizedBox();

        final name = otherUser["fullName"] ?? "No name";
        final avatar = otherUser["avatarUrl"] ?? "";

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
                "conversationId": item["_id"],
                "otherUserId": otherUser?["_id"],
                "name": name,
                "avatar": avatar,
              },
            );
            fetchData();  // ← gọi lại sau khi pop về
          },
        );
      },
    );
  }


  String _getLastMessage(Map<String, dynamic> item) {
    final lastMsg = item["lastMessageId"];
    if (lastMsg == null || lastMsg is! Map) return "Bắt đầu cuộc trò truyện";

    // Kiểm tra thu hồi / xóa trước
    if (lastMsg["isRecalled"] == true) return "Tin nhắn đã bị thu hồi";
    if (lastMsg["isDeleted"] == true) return "Tin nhắn đã bị xóa";

    final type = lastMsg["type"] ?? "text";
    if (type == "text") {
      return lastMsg["content"] ?? "";
    } else if (type == "image") {
      return "📷 Hình ảnh";
    } else if (type == "file") {
      return "📎 Tệp đính kèm";
    }
    return "";
  }

  String _getLastTime(Map<String, dynamic> item) {
    final lastMsg = item["lastMessageId"];
    if (lastMsg == null || lastMsg is! Map) return "";

    final raw = lastMsg["createdAt"];
    if (raw == null) return "";

    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        // Hôm nay → hiện giờ:phút
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      } else {
        // Hôm khác → hiện ngày/tháng
        return "${dt.day}/${dt.month}";
      }
    } catch (_) {
      return "";
    }
  }
}