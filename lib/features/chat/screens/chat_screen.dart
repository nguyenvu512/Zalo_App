import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_appbar.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_message.dart';
import 'package:zalo_mobile_app/features/chat/screens/message_option.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';
import 'chat_input.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String otherUserId;
  final String avatar;
  final String type;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.otherUserId,
    required this.avatar,
    required this.type,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatController = ChatController();
  final TextEditingController _controller = TextEditingController();
  final storage = FlutterSecureStorage();
  Map<String, dynamic>? _replyingMessage;
  String? _currentUserIdCache;

  bool isLoading = false;
  double _inputHeight = 50;

  List<Map<String, dynamic>> messages = [];
  StreamSubscription? _socketSub;

  String? getSenderId(Map<String, dynamic> message) {
    final sender = message["senderId"];
    if (sender is Map) return sender["_id"]?.toString();
    return sender?.toString();
  }

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
    loadMessages();

    _socketSub = SocketService().eventsStream.listen((event) {
      final eventName = event["event"];
      final data = event["data"];

      if (!mounted) return;

      switch (eventName) {
        case "receive_message":
          final raw = data["message"];
          Map<String, dynamic> message;

          if (raw is String) {
            message = jsonDecode(raw);
          } else {
            message = Map<String, dynamic>.from(raw);
          }

          setState(() {
            messages.insert(0, message);
          });
          break;

        case "message_recalled":
          setState(() {
            final i = messages.indexWhere((m) => m["_id"] == data["messageId"]);
            if (i != -1) {
              messages[i] = {
                ...messages[i],
                "isRecalled": true,
              };
            }
          });
          break;

        case "message_deleted":
          setState(() {
            final i = messages.indexWhere((m) => m["_id"] == data["messageId"]);
            if (i != -1) {
              messages[i] = {
                ...messages[i],
                "isDeleted": true,
              };
            }
          });
          break;
      }
    });
  }

  Future<void> _initCurrentUser() async {
    final userId = await storage.read(key: "user_id");
    if (!mounted) return;
    setState(() {
      _currentUserIdCache = userId;
    });
  }

  Widget _buildReplyPreview() {
    final replying = _replyingMessage;
    if (replying == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getReplySenderName(replying),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getReplyPreviewText(replying),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _replyingMessage = null;
              });
            },
            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  void loadMessages() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await chatController.getMessages(widget.conversationId);

      setState(() {
        if (widget.type == 'group') {
          messages = data.map((msg) {
            final messageMap = Map<String, dynamic>.from(msg);
            messageMap['chatType'] = 'group';
            return messageMap;
          }).toList();
        } else {
          messages = data.map((msg) => Map<String, dynamic>.from(msg)).toList();
        }
        isLoading = false;
      });
      print(messages);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void handleSend({String? text, File? file, required String type}) async {
    final userId = _currentUserIdCache ?? await storage.read(key: "user_id");

    final content = text ?? "";
    final localPath = file?.path ?? "";
    final replyToMessageId = _replyingMessage?["_id"]?.toString();

    setState(() {
      _replyingMessage = null;
      messages.insert(0, {
        "_id": "",
        "senderId": userId,
        "type": type,
        "content": type == "image" ? localPath : content,
        "attachments": [],
        "replyToMessageId": _replyingMessage,
        "status": "sending",
        "isRecalled": false,
        "isDeleted": false,
        "createdAt": DateTime.now().toIso8601String(),
      });
    });

    final insertedIndex = 0;

    try {
      final res = await chatController.sendMessage(
        conversationId: widget.conversationId,
        senderId: userId ?? "",
        content: content,
        file: file,
        type: type,
        replyToMessageId: replyToMessageId,
      );

      final message = res["result"];

      SocketService().emit("send_message", {
        "userId": userId,
        "toUserId": widget.otherUserId,
        "message": message,
      });

      setState(() {
        messages[insertedIndex] = Map<String, dynamic>.from(message);
      });
    } catch (e) {
      setState(() {
        messages[insertedIndex]["status"] = "error";
      });
    }
  }

  String _getReplySenderName(Map<String, dynamic> message) {
    final sender = message["senderId"];

    if (sender is Map<String, dynamic>) {
      final senderId = sender["_id"]?.toString();
      if (senderId == null) return sender["fullName"]?.toString() ?? "Người dùng";

      if (senderId == widget.otherUserId) {
        return widget.name;
      }

      final currentUserId = _currentUserIdCache;
      if (currentUserId != null && senderId == currentUserId) {
        return "Bạn";
      }

      return sender["fullName"]?.toString() ?? "Người dùng";
    }

    return "Người dùng";
  }

  String _getReplyPreviewText(Map<String, dynamic> message) {
    final type = message["type"]?.toString() ?? "text";

    if (message["isRecalled"] == true) {
      return "Tin nhắn đã bị thu hồi";
    }

    switch (type) {
      case "image":
        return "📷 Hình ảnh";
      case "sticker":
        return "Sticker";
      case "file":
        final attachments = message["attachments"];
        if (attachments is List && attachments.isNotEmpty) {
          final first = attachments.first;
          if (first is Map<String, dynamic>) {
            return first["fileName"]?.toString() ?? "Tệp đính kèm";
          }
        }
        return "Tệp đính kèm";
      case "text":
      default:
        final content = message["content"]?.toString() ?? "";
        return content.isNotEmpty ? content : "Tin nhắn";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/images/chat_background.jpg",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? const Center(
                child: Text(
                  "Chưa có tin nhắn",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.only(
                  top: 70,
                  bottom: _inputHeight,
                ),
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    final currentSenderId = getSenderId(msg);
                    final nextSenderId = index < messages.length - 1
                        ? getSenderId(messages[index + 1])
                        : null;

                    final isDifferentSender =
                        index < messages.length - 1 &&
                            currentSenderId != nextSenderId;

                    return Padding(
                      padding: EdgeInsets.only(
                        top: widget.type == 'group'
                            ? (isDifferentSender ? 12 : 2)
                            : 2,
                      ),
                      child: ChatMessage(
                        message: msg,
                        onLongPress: () async {
                          final updatedMessage = await MessageOption.show(
                            context: context,
                            otherUserId: widget.otherUserId,
                            message: msg,
                            onSuccess: (result, messageId) {
                              final i = messages.indexWhere((m) => m["_id"] == messageId);

                              switch (result) {
                                case MessageOptionResult.deleted:
                                  if (i == -1) return;
                                  setState(() {
                                    messages[i] = {
                                      ...messages[i],
                                      "isDeleted": true,
                                    };
                                  });
                                  break;

                                case MessageOptionResult.recalled:
                                  if (i == -1) return;
                                  setState(() {
                                    messages[i] = {
                                      ...messages[i],
                                      "isRecalled": true,
                                    };
                                  });
                                  break;

                                case MessageOptionResult.replied:
                                  if (i == -1) return;
                                  setState(() {
                                    _replyingMessage = Map<String, dynamic>.from(messages[i]);
                                  });
                                  break;
                              }
                            },
                          );

                          if (updatedMessage != null) {
                            final updated = Map<String, dynamic>.from(updatedMessage);
                            final i = messages.indexWhere((m) => m["_id"] == updated["_id"]);

                            if (i != -1) {
                              setState(() {
                                messages[i] = {
                                  ...messages[i],
                                  ...updated,
                                };
                              });
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(
              name: widget.name,
              avatar: widget.avatar,
              type: widget.type,
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildReplyPreview(),
                ChatInput(
                  controller: _controller,
                  onSend: handleSend,
                  onHeightChanged: (height) {
                    final extraReplyHeight = _replyingMessage != null ? 64.0 : 0.0;
                    final finalHeight = height + extraReplyHeight;

                    if (_inputHeight != finalHeight) {
                      setState(() {
                        _inputHeight = finalHeight;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}