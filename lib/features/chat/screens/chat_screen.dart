import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_appbar.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_message.dart';
import 'package:zalo_mobile_app/features/chat/screens/message_option.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_setting_screen.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
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
  final storage = const FlutterSecureStorage();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _replyingMessage;
  String? _currentUserIdCache;
  String? _highlightedMessageId;

  final Map<String, GlobalKey> _messageKeys = {};

  bool isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  double _inputHeight = 50;

  int _currentPage = 1;
  static const int _pageSize = 20;
  static const double _estimatedItemHeight = 110;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> pinnedMessages = [];
  bool _isPinnedExpanded = false;

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
    _loadPinnedMessages();

    _scrollController.addListener(_onScroll);

    SocketService().listenEvent("receive_message");
    SocketService().listenEvent("receive_group_message");
    SocketService().listenEvent("message_recalled");
    SocketService().listenEvent("message_deleted");
    SocketService().listenEvent("message_reacted");
    SocketService().listenEvent("message_pinned");
    SocketService().listenEvent("message_unpinned");
    SocketService().listenEvent("group_disbanded");
    SocketService().listenEvent("removed_from_group");

    _socketSub = SocketService().eventsStream.listen((event) {
      final eventName = event["event"];
      final data = event["data"];

      if (!mounted) return;

      switch (eventName) {
        case "receive_message":
          final raw = data["message"];
          Map<String, dynamic> message;

          if (raw is String) {
            message = Map<String, dynamic>.from(jsonDecode(raw));
          } else {
            message = Map<String, dynamic>.from(raw);
          }

          message["chatType"] = "direct";

          final incomingId = message["_id"]?.toString();
          final existed =
          messages.any((m) => m["_id"]?.toString() == incomingId);

          if (existed) return;

          setState(() {
            messages.insert(0, message);
          });
          break;

        case "receive_group_message":
          final raw = data["message"];
          Map<String, dynamic> message;

          if (raw is String) {
            message = Map<String, dynamic>.from(jsonDecode(raw));
          } else {
            message = Map<String, dynamic>.from(raw);
          }

          message["chatType"] = "group";

          final incomingId = message["_id"]?.toString();
          final existed =
          messages.any((m) => m["_id"]?.toString() == incomingId);

          if (existed) return;

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

        case "message_reacted":
          final updated = Map<String, dynamic>.from(data["message"]);
          final messageId = updated["_id"]?.toString();

          if (messageId == null || messageId.isEmpty) break;

          setState(() {
            final i = messages.indexWhere(
                  (m) => m["_id"]?.toString() == messageId,
            );

            if (i != -1) {
              messages[i] = {
                ...messages[i],
                ...updated,
              };
            }
          });
          break;

        case "message_pinned":
          final pinnedMessage = Map<String, dynamic>.from(data["message"]);
          final pinnedId = pinnedMessage["_id"]?.toString();

          if (pinnedId == null || pinnedId.isEmpty) break;

          setState(() {
            final i = messages.indexWhere(
                  (m) => m["_id"]?.toString() == pinnedId,
            );

            if (i != -1) {
              messages[i] = {
                ...messages[i],
                "isPinned": true,
              };
            }

            final existed = pinnedMessages.any((item) {
              final raw = item["messageId"];
              if (raw is Map<String, dynamic>) {
                return raw["_id"]?.toString() == pinnedId;
              }
              return false;
            });

            if (!existed) {
              pinnedMessages.insert(0, {
                "messageId": {
                  ...pinnedMessage,
                  "isPinned": true,
                }
              });
            }
          });
          break;

        case "message_unpinned":
          final unpinnedMessage = Map<String, dynamic>.from(data["message"]);
          final unpinnedId = unpinnedMessage["_id"]?.toString();

          if (unpinnedId == null || unpinnedId.isEmpty) break;

          setState(() {
            final i = messages.indexWhere(
                  (m) => m["_id"]?.toString() == unpinnedId,
            );

            if (i != -1) {
              messages[i] = {
                ...messages[i],
                "isPinned": false,
              };
            }

            pinnedMessages.removeWhere((item) {
              final raw = item["messageId"];
              if (raw is Map<String, dynamic>) {
                return raw["_id"]?.toString() == unpinnedId;
              }
              return false;
            });

            if (pinnedMessages.isEmpty) {
              _isPinnedExpanded = false;
            }
          });
          break;

        case "group_disbanded":
          if (data is! Map) break;

          final conversationId = data["conversationId"]?.toString() ?? "";
          if (conversationId != widget.conversationId) break;

          final message =
              data["message"]?.toString() ?? "Nhóm đã bị giải tán";

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );

          context.go(AppRoutes.home);
          break;

        case "removed_from_group":
          if (data is! Map) break;

          final conversationId = data["conversationId"]?.toString() ?? "";
          if (conversationId != widget.conversationId) break;

          final message =
              data["message"]?.toString() ?? "Nhóm đã bị giải tán";

          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );

          context.go(AppRoutes.home);
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

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_isLoadingMore || isLoading || !_hasMoreMessages) return;

    const threshold = 200.0;
    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadOlderMessages();
    }
  }

  Future<void> _loadPinnedMessages() async {
    try {
      final data = await chatController.getPinnedMessages(
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      setState(() {
        pinnedMessages = List<Map<String, dynamic>>.from(
          data.map((e) => Map<String, dynamic>.from(e)),
        );
      });
    } catch (e) {
      debugPrint("❌ load pinned messages error: $e");
      if (!mounted) return;
      setState(() {
        pinnedMessages = [];
      });
    }
  }

  String _getPinnedPreview(Map<String, dynamic> item) {
    final rawMessage = item["messageId"];
    if (rawMessage is! Map) return "Tin nhắn đã ghim";

    final message = Map<String, dynamic>.from(rawMessage);
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
          if (first is Map) {
            return first["fileName"]?.toString() ?? "Tệp đính kèm";
          }
        }
        return "Tệp đính kèm";
      case "mixed":
        return "Tin nhắn hỗn hợp";
      case "text":
      default:
        final content = message["content"]?.toString() ?? "";
        return content.trim().isNotEmpty ? content : "Tin nhắn";
    }
  }

  String _getPinnedSenderName(Map<String, dynamic> item) {
    final rawMessage = item["messageId"];
    if (rawMessage is! Map) return "Người dùng";

    final message = Map<String, dynamic>.from(rawMessage);
    final rawSender = message["senderId"];
    if (rawSender is! Map) return "Người dùng";

    final sender = Map<String, dynamic>.from(rawSender);
    final senderId = sender["_id"]?.toString();

    if (senderId == null || senderId.isEmpty) {
      return sender["fullName"]?.toString() ?? "Người dùng";
    }

    if (senderId == widget.otherUserId) return widget.name;
    if (_currentUserIdCache != null && senderId == _currentUserIdCache) {
      return "Bạn";
    }

    return sender["fullName"]?.toString() ?? "Người dùng";
  }

  Future<void> _openConversationSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationSettingScreen(
          conversationId: widget.conversationId,
          name: widget.name,
          avatar: widget.avatar,
          type: widget.type,
        ),
      ),
    );

    if (!mounted || result == null || result is! Map<String, dynamic>) return;

    final removedConversationId =
        result['removedConversationId']?.toString() ?? '';

    if (removedConversationId.isNotEmpty) {
      _closeAfterRemovedConversation(removedConversationId);
      return;
    }

    final targetMessageId = result['targetMessageId']?.toString() ?? '';
    if (targetMessageId.isEmpty) return;

    final found = await _ensureMessageLoaded(targetMessageId);
    if (!found) return;

    await Future.delayed(const Duration(milliseconds: 80));
    await _scrollToMessageById(targetMessageId);
  }

  void _closeAfterRemovedConversation(String conversationId) {
    final result = {
      'removedConversationId': conversationId,
    };

    if (Navigator.of(context).canPop()) {
      context.pop(result);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Widget _buildPinnedBar() {
    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    final latestPinned = Map<String, dynamic>.from(pinnedMessages.first);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _isPinnedExpanded = !_isPinnedExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pinnedMessages.length == 1
                                    ? "Tin nhắn đã ghim"
                                    : "${pinnedMessages.length} tin nhắn đã ghim",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${_getPinnedSenderName(latestPinned)}: ${_getPinnedPreview(latestPinned)}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 180),
                          turns: _isPinnedExpanded ? 0.5 : 0,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isPinnedExpanded)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: pinnedMessages.map((rawItem) {
                        final item = Map<String, dynamic>.from(rawItem);

                        return InkWell(
                          onTap: () async {
                            final msg = item["messageId"];
                            if (msg is! Map<String, dynamic>) return;

                            final targetId = msg["_id"]?.toString() ?? "";
                            if (targetId.isEmpty) return;

                            setState(() {
                              _isPinnedExpanded = false;
                            });

                            final found = await _ensureMessageLoaded(targetId);
                            if (!found) return;

                            await Future.delayed(const Duration(milliseconds: 80));
                            await _scrollToMessageById(targetId);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.push_pin_outlined,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getPinnedSenderName(item),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _getPinnedPreview(item),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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
            icon: const Icon(
              Icons.close,
              size: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loadMessages({int page = 1}) async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await chatController.getMessages(
        widget.conversationId,
        page: page,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        final normalized = widget.type == 'group'
            ? data.map((msg) {
          final messageMap = Map<String, dynamic>.from(msg);
          messageMap['chatType'] = 'group';
          return messageMap;
        }).toList()
            : data.map((msg) => Map<String, dynamic>.from(msg)).toList();

        messages = normalized;
        _currentPage = page;
        _hasMoreMessages = normalized.length >= _pageSize;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    _isLoadingMore = true;

    try {
      final nextPage = _currentPage + 1;

      final oldMaxScrollExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      final oldPixels =
      _scrollController.hasClients ? _scrollController.position.pixels : 0.0;

      final data = await chatController.getMessages(
        widget.conversationId,
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      final normalized = widget.type == 'group'
          ? data.map((msg) {
        final messageMap = Map<String, dynamic>.from(msg);
        messageMap['chatType'] = 'group';
        return messageMap;
      }).toList()
          : data.map((msg) => Map<String, dynamic>.from(msg)).toList();

      if (normalized.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
        return;
      }

      setState(() {
        messages.addAll(normalized);
        _currentPage = nextPage;
        _hasMoreMessages = normalized.length >= _pageSize;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;

        final newMaxScrollExtent = _scrollController.position.maxScrollExtent;
        final delta = newMaxScrollExtent - oldMaxScrollExtent;
        final target = oldPixels + delta;

        _scrollController.jumpTo(target);
      });
    } catch (e) {
      debugPrint("❌ Load older messages failed: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<bool> _ensureMessageLoaded(String targetMessageId) async {
    bool existed =
    messages.any((m) => m["_id"]?.toString() == targetMessageId);
    if (existed) return true;

    while (_hasMoreMessages) {
      final loaded = await _loadNextPageForJump();
      if (!loaded) break;

      existed = messages.any((m) => m["_id"]?.toString() == targetMessageId);
      if (existed) return true;
    }

    return false;
  }

  Future<bool> _loadNextPageForJump() async {
    if (_isLoadingMore || !_hasMoreMessages) return false;

    _isLoadingMore = true;

    try {
      final nextPage = _currentPage + 1;

      final data = await chatController.getMessages(
        widget.conversationId,
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return false;

      final normalized = widget.type == 'group'
          ? data.map((msg) {
        final messageMap = Map<String, dynamic>.from(msg);
        messageMap['chatType'] = 'group';
        return messageMap;
      }).toList()
          : data.map((msg) => Map<String, dynamic>.from(msg)).toList();

      setState(() {
        messages.addAll(normalized);
        _currentPage = nextPage;
        _hasMoreMessages = normalized.length >= _pageSize;
      });

      return normalized.isNotEmpty;
    } catch (e) {
      return false;
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _scrollToMessageById(String messageId) async {
    final targetIndex =
    messages.indexWhere((m) => m["_id"]?.toString() == messageId);

    if (targetIndex == -1) return;

    for (int attempt = 0; attempt < 6; attempt++) {
      final key = _messageKeys[messageId];
      final targetContext = key?.currentContext;

      if (targetContext != null) {
        await Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.35,
        );

        if (!mounted) return;

        setState(() {
          _highlightedMessageId = messageId;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (_highlightedMessageId == messageId) {
            setState(() {
              _highlightedMessageId = null;
            });
          }
        });

        return;
      }

      if (!_scrollController.hasClients) return;

      final roughOffset = (targetIndex * _estimatedItemHeight)
          .clamp(0, _scrollController.position.maxScrollExtent)
          .toDouble();

      await _scrollController.animateTo(
        roughOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _handleReplyTap(Map<String, dynamic> msg) async {
    final replied = msg["replyToMessageId"];
    if (replied is! Map<String, dynamic>) return;

    final targetId = replied["_id"]?.toString() ?? "";
    if (targetId.isEmpty) return;

    final found = await _ensureMessageLoaded(targetId);
    if (!found) return;

    await Future.delayed(const Duration(milliseconds: 80));
    await _scrollToMessageById(targetId);
  }

  void handleSend({String? text, File? file, required String type}) async {
    final userId = _currentUserIdCache ?? await storage.read(key: "user_id");

    final content = text ?? "";
    final localPath = file?.path ?? "";
    final replyToMessageId = _replyingMessage?["_id"]?.toString();
    final replyingSnapshot = _replyingMessage;

    setState(() {
      _replyingMessage = null;
      messages.insert(0, {
        "_id": "",
        "senderId": userId,
        "type": type,
        "content": type == "image" ? localPath : content,
        "attachments": [],
        "replyToMessageId": replyingSnapshot,
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

      if (widget.type == 'group') {
        SocketService().emit("send_group_message", {
          "groupId": widget.conversationId,
          "userId": userId,
          "message": message,
        });
      } else {
        SocketService().emit("send_message", {
          "userId": userId,
          "toUserId": widget.otherUserId,
          "message": message,
        });
      }

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
      if (senderId == null) {
        return sender["fullName"]?.toString() ?? "Người dùng";
      }

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
      case "mixed":
        return "Tin nhắn hỗn hợp";
      case "text":
      default:
        final content = message["content"]?.toString() ?? "";
        return content.isNotEmpty ? content : "Tin nhắn";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.only(top: 8, bottom: 0),
                  itemCount: messages.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    }

                    final msg = messages[index];
                    final msgId = msg["_id"]?.toString() ?? "";

                    if (msgId.isNotEmpty) {
                      _messageKeys.putIfAbsent(
                        msgId,
                            () => GlobalKey(),
                      );
                    }

                    final currentSenderId = getSenderId(msg);
                    final nextSenderId = index < messages.length - 1
                        ? getSenderId(messages[index + 1])
                        : null;

                    final isDifferentSender =
                        index < messages.length - 1 &&
                            currentSenderId != nextSenderId;

                    final isPinned = pinnedMessages.any((item) {
                      final pinnedMsg = item["messageId"];
                      if (pinnedMsg is Map<String, dynamic>) {
                        return pinnedMsg["_id"]?.toString() == msgId;
                      }
                      return false;
                    });

                    final popupMessage = {
                      ...msg,
                      "isPinned": isPinned,
                    };

                    return Padding(
                      key: msgId.isNotEmpty ? _messageKeys[msgId] : null,
                      padding: EdgeInsets.only(
                        top: widget.type == 'group'
                            ? (isDifferentSender ? 12 : 2)
                            : 2,
                      ),
                      child: ChatMessage(
                        message: msg,
                        isHighlighted: _highlightedMessageId == msgId,
                        onReplyTap: () => _handleReplyTap(msg),
                        onLongPress: () async {
                          final result = await MessageOption.show(
                            context: context,
                            otherUserId: widget.otherUserId,
                            message: popupMessage,
                            conversationId: widget.conversationId,
                            chatType: widget.type,
                            onSuccess: (result, messageId) {
                              final i = messages.indexWhere(
                                    (m) => m["_id"] == messageId,
                              );

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
                                    _replyingMessage =
                                    Map<String, dynamic>.from(
                                      messages[i],
                                    );
                                  });
                                  break;
                              }
                            },
                          );

                          if (result != null) {
                            final action =
                                result["action"]?.toString() ?? "";

                            if (action == "reaction") {
                              final updated =
                              Map<String, dynamic>.from(
                                result["message"],
                              );
                              final i = messages.indexWhere(
                                    (m) => m["_id"] == updated["_id"],
                              );

                              if (i != -1) {
                                setState(() {
                                  messages[i] = {
                                    ...messages[i],
                                    ...updated,
                                  };
                                });
                              }
                            }

                            if (action == "pin" || action == "unpin") {
                              final pinned =
                              (result["pinnedMessages"] as List? ?? [])
                                  .map((e) =>
                              Map<String, dynamic>.from(e))
                                  .toList();

                              setState(() {
                                pinnedMessages = pinned;
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
              conversationId: widget.conversationId,
              onOpenSettings: _openConversationSettings,
            ),
          ),
          if (pinnedMessages.isNotEmpty)
            Positioned(
              top: 78,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: _buildPinnedBar(),
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
                    final extraReplyHeight =
                    _replyingMessage != null ? 64.0 : 0.0;
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