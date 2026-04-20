import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_item.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

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

  StreamSubscription<Map<String, dynamic>>? _socketSub;

  @override
  void initState() {
    super.initState();
    fetchData();

    _socketSub = SocketService().eventsStream.listen((event) {
      final eventName = event["event"];
      final data = event["data"];

      if (!mounted) return;

      switch (eventName) {
        case "group_disbanded":
          if (data is! Map) break;

          final conversationId = data["conversationId"]?.toString() ?? "";
          if (conversationId.isEmpty) break;

          setState(() {
            conversations.removeWhere(
                  (item) =>
              item is Map<String, dynamic> &&
                  item["_id"]?.toString() == conversationId,
            );
          });
          break;

        case "added_to_group":
          if (data is! Map) break;

          final conversationId = data["conversationId"]?.toString() ?? "";
          if (conversationId.isEmpty) break;

          final exists = conversations.any(
                (item) =>
            item is Map<String, dynamic> &&
                item["_id"]?.toString() == conversationId,
          );

          if (exists) break;

          setState(() {
            conversations.insert(0, {
              "_id": conversationId,
              "type": "group",
              "name": data["groupName"]?.toString() ?? "Nhóm chat",
              "avatarUrl": data["avatarUrl"]?.toString() ?? "",
              "lastMessageId": null,
              "lastMessageAt": DateTime.now().toIso8601String(),
            });
          });
          break;
        case "removed_from_group":
          if (data is! Map) break;

          final conversationId = data["conversationId"]?.toString() ?? "";
          if (conversationId.isEmpty) break;

          setState(() {
            conversations.removeWhere(
                  (item) =>
              item is Map<String, dynamic> &&
                  item["_id"]?.toString() == conversationId,
            );
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
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

      if (id.toString() != currentUserId.toString()) {
        return user;
      }
    }

    return null;
  }

  String _stripHtml(String input) {
    var text = input;

    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<li>', caseSensitive: false), '• ');
    text = text.replaceAll(RegExp(r'</li>', caseSensitive: false), '\n');

    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    text = text.replaceAll(RegExp(r'\n+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  String _getConversationName(Map<String, dynamic> item) {
    final type = (item["type"] ?? "direct").toString();

    if (type == "group") {
      final name = (item["name"] ?? "").toString().trim();
      return name.isNotEmpty ? name : "Nhóm chat";
    }

    final otherUser = getOtherUser(item["members"] as List?);
    return (otherUser?["fullName"] ?? "No name").toString();
  }

  String _getConversationAvatar(Map<String, dynamic> item) {
    final type = (item["type"] ?? "direct").toString();

    if (type == "group") {
      return (item["avatarUrl"] ?? "").toString();
    }

    final otherUser = getOtherUser(item["members"] as List?);
    return (otherUser?["avatarUrl"] ?? "").toString();
  }

  String _getOtherUserIdForDirect(Map<String, dynamic> item) {
    final otherUser = getOtherUser(item["members"] as List?);
    return (otherUser?["_id"] ?? "").toString();
  }

  String _getLastMessage(Map<String, dynamic> item) {
    final lastMsg = item["lastMessageId"];
    if (lastMsg == null || lastMsg is! Map) {
      return "Bắt đầu cuộc trò chuyện";
    }

    if (lastMsg["isRecalled"] == true) return "Tin nhắn đã bị thu hồi";
    if (lastMsg["isDeleted"] == true) return "Tin nhắn đã bị xóa";

    final type = lastMsg["type"] ?? "text";
    final content = _stripHtml((lastMsg["content"] ?? "").toString());
    final attachments = lastMsg["attachments"] as List? ?? [];

    final hasAttachments = attachments.isNotEmpty;

    switch (type) {
      case "text":
        return content.isNotEmpty ? content : "Tin nhắn";

      case "sticker":
        return "Sticker";
      case "image":
        return "🖼 Hình ảnh";

      case "file":
        return "📎 Tệp đính kèm";

      case "audio":
        return "🎵 Âm thanh";

      case "video":
        return "🎬 Video";

      case "mixed":
        if (hasAttachments) {
          final first = attachments.first;

          final attachmentType = first is Map
              ? (first["type"]?.toString() ?? "")
              : "";

          if (attachmentType == "image") {
            return content.isNotEmpty ? "🖼 $content" : "🖼 Hình ảnh";
          }

          if (attachmentType == "file") {
            return content.isNotEmpty ? "📎 $content" : "📎 Tệp đính kèm";
          }

          if (attachmentType == "audio") {
            return content.isNotEmpty ? "🎵 $content" : "🎵 Âm thanh";
          }

          if (attachmentType == "video") {
            return content.isNotEmpty ? "🎬 $content" : "🎬 Video";
          }
        }

        return content.isNotEmpty ? content : "Tin nhắn";

      default:
        return content.isNotEmpty ? content : "Tin nhắn mới";
    }
  }

  String _getLastTime(Map<String, dynamic> item) {
    final raw = item["lastMessageAt"] ??
        (item["lastMessageId"] is Map
            ? item["lastMessageId"]["createdAt"]
            : null);
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

        final conversationId = (item["_id"] ?? "").toString();
        final type = (item["type"] ?? "direct").toString();

        final name = _getConversationName(item);
        final avatar = _getConversationAvatar(item);

        final otherUserId =
        type == "direct" ? _getOtherUserIdForDirect(item) : "";

        return ConversationItem(
          name: name,
          avatarUrl: avatar,
          lastMessage: _getLastMessage(item),
          time: _getLastTime(item),
          unreadCount: 0,
          type: type,
          onTap: () async {
            const chatbotUserId = "680000000000000000000001";

            if (otherUserId == chatbotUserId) {
              await context.push(
                AppRoutes.chatbotScreen,
                extra: {
                  "conversationId": conversationId,
                  "name": name,
                  "avatar": avatar,
                  "type": "bot"
                },
              );
            } else {
              final result = await context.push(
                AppRoutes.chatScreen,
                extra: {
                  "conversationId": conversationId,
                  "otherUserId": otherUserId,
                  "name": name,
                  "avatar": avatar,
                  "type": type,
                },
              );

              if (!mounted) return;

              if (result is Map<String, dynamic>) {
                final removedConversationId =
                    result['removedConversationId']?.toString() ?? '';

                if (removedConversationId.isNotEmpty) {
                  setState(() {
                    conversations.removeWhere(
                          (item) =>
                      item is Map<String, dynamic> &&
                          item["_id"]?.toString() == removedConversationId,
                    );
                  });
                  return;
                }
              }

              await fetchData();
            }
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
      child:
      conversations.isEmpty ? _buildEmptyState() : _buildConversationList(),
    );
  }
}