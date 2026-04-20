import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_appbar.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_input.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_message.dart';
import 'package:zalo_mobile_app/features/chat/screens/message_chat_bot.dart';
import 'package:zalo_mobile_app/features/conversation/screens/conversation_setting_screen.dart';

class ChatBotScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatBotScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final ChatController _chatController = ChatController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Map<String, GlobalKey> _messageKeys = {};

  List<Map<String, dynamic>> messages = [];

  String? _currentUserId;
  String? _highlightedMessageId;

  late String _currentName;
  late String _currentAvatar;
  late String _conversationType;

  bool isLoading = false;
  bool isBotTyping = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;

  double _inputHeight = 50;

  int _currentPage = 1;
  static const int _pageSize = 20;
  static const double _estimatedItemHeight = 110;

  String get conversationId => widget.conversation["_id"]?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    _currentName = widget.conversation["name"]?.toString() ?? "Trợ lý AI";
    _currentAvatar = widget.conversation["avatarUrl"]?.toString() ?? "";
    _conversationType = widget.conversation["type"]?.toString() ?? "direct";

    _init();
  }

  Future<void> _init() async {
    await _loadCurrentUser();
    await loadMessages();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _storage.read(key: "user_id");
    if (!mounted) return;

    setState(() {
      _currentUserId = userId;
    });
  }

  String? getSenderId(Map<String, dynamic> message) {
    final sender = message["senderId"];
    if (sender is Map) return sender["_id"]?.toString();
    return sender?.toString();
  }

  bool _isCurrentUserMessage(Map<String, dynamic> message) {
    final senderId = getSenderId(message);
    return senderId == _currentUserId;
  }

  List<Map<String, dynamic>> _normalizeMessages(List<dynamic> data) {
    return data
        .map<Map<String, dynamic>>(
          (msg) => Map<String, dynamic>.from(msg as Map),
    )
        .toList();
  }

  Future<void> loadMessages({int page = 1}) async {
    try {
      if (!mounted) return;

      setState(() {
        isLoading = true;
      });

      final data = await _chatController.getMessages(
        conversationId,
        page: page,
        limit: _pageSize,
      );

      if (!mounted) return;

      final normalized = _normalizeMessages(data);

      setState(() {
        messages = normalized;
        _currentPage = page;
        _hasMoreMessages = normalized.length >= _pageSize;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Load chatbot messages failed: $e");

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
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

      final data = await _chatController.getMessages(
        conversationId,
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      final normalized = _normalizeMessages(data);

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
      debugPrint("❌ Load older chatbot messages failed: $e");
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<bool> _loadNextPageForJump() async {
    if (_isLoadingMore || !_hasMoreMessages) return false;

    _isLoadingMore = true;

    try {
      final nextPage = _currentPage + 1;

      final data = await _chatController.getMessages(
        conversationId,
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return false;

      final normalized = _normalizeMessages(data);

      setState(() {
        messages.addAll(normalized);
        _currentPage = nextPage;
        _hasMoreMessages = normalized.length >= _pageSize;
      });

      return normalized.isNotEmpty;
    } catch (e) {
      debugPrint("❌ Load next page for jump chatbot failed: $e");
      return false;
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

  Future<void> _openConversationSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConversationSettingScreen(
          conversationId: conversationId,
          name: _currentName,
          avatar: _currentAvatar,
          type: _conversationType,
        ),
      ),
    );

    if (!mounted || result == null || result is! Map<String, dynamic>) return;

    final updatedName = result["name"]?.toString();
    final updatedAvatar = result["avatar"]?.toString();
    final targetMessageId = result["targetMessageId"]?.toString() ?? "";

    setState(() {
      if (updatedName != null && updatedName.isNotEmpty) {
        _currentName = updatedName;
      }
      if (updatedAvatar != null) {
        _currentAvatar = updatedAvatar;
      }
    });

    if (targetMessageId.isEmpty) return;

    final found = await _ensureMessageLoaded(targetMessageId);
    if (!found) return;

    await Future.delayed(const Duration(milliseconds: 80));
    await _scrollToMessageById(targetMessageId);
  }

  Future<void> handleSend({
    String? text,
    File? file,
    required String type,
  }) async {
    if (type != "text") return;

    final content = text?.trim() ?? "";
    if (content.isEmpty) return;

    final userId = _currentUserId ?? await _storage.read(key: "user_id");
    if (userId == null || userId.isEmpty) return;

    final beforeServerIds = messages
        .map((m) => m["_id"]?.toString() ?? "")
        .where((id) => id.isNotEmpty && !id.startsWith("local_"))
        .toSet();

    final localMessage = <String, dynamic>{
      "_id": "local_${DateTime.now().millisecondsSinceEpoch}",
      "senderId": userId,
      "type": "text",
      "content": content,
      "attachments": const [],
      "status": "sending",
      "isRecalled": false,
      "isDeleted": false,
      "createdAt": DateTime.now().toIso8601String(),
    };

    _controller.clear();

    if (!mounted) return;

    setState(() {
      messages.insert(0, localMessage);
      isBotTyping = true;
    });

    try {
      await _chatController.sendChatbotMessage(
        conversationId: conversationId,
        content: content,
      );

      if (!mounted) return;

      final index = messages.indexWhere((m) => m["_id"] == localMessage["_id"]);
      if (index != -1) {
        setState(() {
          messages[index]["status"] = "sent";
        });
      }

      await _waitForBotReply(beforeServerIds);
    } catch (e) {
      debugPrint("❌ Send chatbot message failed: $e");

      if (!mounted) return;

      final index = messages.indexWhere((m) => m["_id"] == localMessage["_id"]);
      if (index != -1) {
        setState(() {
          messages[index]["status"] = "error";
          isBotTyping = false;
        });
      } else {
        setState(() {
          isBotTyping = false;
        });
      }
    }
  }

  Future<void> _waitForBotReply(Set<String> beforeServerIds) async {
    const maxAttempts = 8;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await Future.delayed(const Duration(milliseconds: 900));

        final requestedLimit = _currentPage * _pageSize;

        final data = await _chatController.getMessages(
          conversationId,
          page: 1,
          limit: requestedLimit,
        );

        if (!mounted) return;

        final freshMessages = _normalizeMessages(data);

        final hasNewBotMessage = freshMessages.any((m) {
          final id = m["_id"]?.toString() ?? "";
          if (id.isEmpty) return false;
          return !beforeServerIds.contains(id) && !_isCurrentUserMessage(m);
        });

        setState(() {
          messages = freshMessages;
          _hasMoreMessages = freshMessages.length >= requestedLimit;
          isBotTyping = !hasNewBotMessage && attempt < maxAttempts - 1;
        });

        if (hasNewBotMessage) {
          return;
        }
      } catch (e) {
        debugPrint("❌ Wait bot reply failed: $e");
      }
    }

    if (!mounted) return;
    setState(() {
      isBotTyping = false;
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
              _currentAvatar.isNotEmpty ? NetworkImage(_currentAvatar) : null,
              backgroundColor: Colors.grey[300],
              child: _currentAvatar.isEmpty
                  ? const Icon(Icons.smart_toy, size: 18, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: const Radius.circular(6),
                ),
                border: Border.all(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
              child: const Text(
                "Bot đang trả lời...",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> msg) {
    final msgId = msg["_id"]?.toString() ?? "";

    if (msgId.isNotEmpty) {
      _messageKeys.putIfAbsent(msgId, () => GlobalKey());
    }

    final isMe = _isCurrentUserMessage(msg);

    return Padding(
      key: msgId.isNotEmpty ? _messageKeys[msgId] : null,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: _highlightedMessageId == msgId
              ? Colors.yellow.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isMe
            ? ChatMessage(message: msg)
            : MessageChatBot(
          message: msg,
          botAvatar: _currentAvatar,
          botName: _currentName,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (messages.isEmpty && !isBotTyping) {
      return const Center(
        child: Text(
          "Hãy bắt đầu hỏi chatbot",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final itemCount =
        messages.length + (isBotTyping ? 1 : 0) + (_isLoadingMore ? 1 : 0);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        top: 70,
        bottom: _inputHeight,
      ),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.only(top: 8, bottom: 0),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (isBotTyping && index == 0) {
            return _buildTypingIndicator();
          }

          final messageStartIndex = isBotTyping ? 1 : 0;
          final messageEndIndex = messageStartIndex + messages.length;

          if (index >= messageStartIndex && index < messageEndIndex) {
            final messageIndex = index - messageStartIndex;
            final msg = messages[messageIndex];
            return _buildMessageItem(msg);
          }

          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
              child: _buildBody(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(
              name: _currentName,
              avatar: _currentAvatar,
              type: _conversationType,
              conversationId: conversationId,
              onOpenSettings: _openConversationSettings,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatInput(
              controller: _controller,
              onSend: handleSend,
              onHeightChanged: (height) {
                if (_inputHeight != height) {
                  setState(() {
                    _inputHeight = height;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}