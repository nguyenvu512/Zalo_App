import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/common/helper/snackbar_helper.dart';
import 'package:zalo_mobile_app/common/popups/custom_dialog.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class ForwardMessagePopup extends StatefulWidget {
  final Map<String, dynamic> message;
  final String currentConversationId;

  const ForwardMessagePopup({
    super.key,
    required this.message,
    required this.currentConversationId,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> message,
    required String currentConversationId,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => ForwardMessagePopup(
        message: message,
        currentConversationId: currentConversationId,
      ),
    );
  }

  @override
  State<ForwardMessagePopup> createState() => _ForwardMessagePopupState();
}

class _ForwardMessagePopupState extends State<ForwardMessagePopup> {
  final storage = const FlutterSecureStorage();
  final conversationController = ConversationController();
  final chatController = ChatController();

  bool isLoading = true;
  String? sendingConversationId;
  String? errorText;
  List<Map<String, dynamic>> conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() {
        isLoading = true;
        errorText = null;
      });

      final data = await conversationController.getListConversation();

      final filtered = (data ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .where((conv) {
        final id = conv["_id"]?.toString() ?? "";
        return id != widget.currentConversationId;
      }).toList();

      setState(() {
        conversations = filtered;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorText = "Không tải được danh sách cuộc trò chuyện";
      });
    }
  }

  Map<String, dynamic>? _getOtherMember(
      Map<String, dynamic> conv,
      String? currentUserId,
      ) {
    final members = conv["members"];
    if (members is! List) return null;

    for (final item in members) {
      if (item is Map<String, dynamic>) {
        final user = item["userId"];
        if (user is Map<String, dynamic>) {
          final memberId = user["_id"]?.toString() ?? "";
          if (memberId != (currentUserId ?? "")) {
            return user;
          }
        }
      }
    }
    return null;
  }

  String _getConversationName(
      Map<String, dynamic> conv,
      String? currentUserId,
      ) {
    final type = conv["type"]?.toString() ?? "direct";

    if (type == "group") {
      final name = conv["name"]?.toString() ?? "";
      return name.isNotEmpty ? name : "Nhóm";
    }

    final otherUser = _getOtherMember(conv, currentUserId);
    return otherUser?["fullName"]?.toString() ?? "Người dùng";
  }

  String _getConversationAvatar(
      Map<String, dynamic> conv,
      String? currentUserId,
      ) {
    final type = conv["type"]?.toString() ?? "direct";

    if (type == "group") {
      return conv["avatarUrl"]?.toString() ?? "";
    }

    final otherUser = _getOtherMember(conv, currentUserId);
    return otherUser?["avatarUrl"]?.toString() ?? "";
  }

  String? _getForwardTargetUserId(
      Map<String, dynamic> conv,
      String? currentUserId,
      ) {
    final type = conv["type"]?.toString() ?? "direct";

    if (type == "group") {
      return null;
    }

    final otherUser = _getOtherMember(conv, currentUserId);
    return otherUser?["_id"]?.toString();
  }

  Future<void> _forwardToConversation(Map<String, dynamic> conv) async {
    final conversationId = conv["_id"]?.toString() ?? "";
    if (conversationId.isEmpty) return;
    if (sendingConversationId != null) return;

    try {
      setState(() {
        sendingConversationId = conversationId;
        errorText = null;
      });

      final userId = await storage.read(key: "user_id");
      if (userId == null || userId.isEmpty) {
        throw Exception("Không tìm thấy user_id");
      }

      final originalType = (widget.message["type"] ?? "text").toString();
      final originalContent = (widget.message["content"] ?? "").toString();

      final rawAttachments = widget.message["attachments"];
      final attachments = rawAttachments is List
          ? rawAttachments.map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      final res = await chatController.sendMessage(
        conversationId: conversationId,
        senderId: userId,
        content: originalContent,
        file: null,
        type: originalType,
        attachments: attachments,
        isForwarded: true,
      );

      final message = res["result"];
      final toUserId = _getForwardTargetUserId(conv, userId);

      // SocketService().emit("send_message", {
      //   "userId": userId,
      //   "toUserId": toUserId,
      //   "message": message,
      // });

      if (!mounted) return;
      Navigator.pop(context);
      SnackBarHelper.show(context, "Chuyển tiếp thành công");
    } catch (e) {
      setState(() {
        sendingConversationId = null;
        errorText = "Chuyển tiếp thất bại";
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: storage.read(key: "user_id"),
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                      child: Row(
                        children: [
                          Icon(Icons.forward_to_inbox, size: 22),
                          SizedBox(width: 10),
                          Text(
                            "Chuyển tiếp tin nhắn",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(30),
                        child: CircularProgressIndicator(),
                      )
                    else if (conversations.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text("Không có cuộc trò chuyện nào để chuyển tiếp"),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Colors.black.withOpacity(0.08),
                          ),
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            final convId = conv["_id"]?.toString() ?? "";
                            final isThisSending = sendingConversationId == convId;

                            final type = conv["type"]?.toString() ?? "direct";
                            final name = _getConversationName(conv, currentUserId);
                            final avatar = _getConversationAvatar(conv, currentUserId);

                            return ListTile(
                              enabled: sendingConversationId == null,
                              onTap: () => _forwardToConversation(conv),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty
                                    ? Icon(
                                  type == "group"
                                      ? Icons.group
                                      : Icons.person,
                                )
                                    : null,
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                type == "group" ? "Nhóm" : "Cá nhân",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: isThisSending
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.chevron_right),
                            );
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: sendingConversationId != null
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text("Đóng"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}