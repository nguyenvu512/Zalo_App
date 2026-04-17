import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_appbar.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_input.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_message.dart';

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

  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool isBotTyping = false;
  String? currentUserId;

  String get conversationId => widget.conversation["_id"]?.toString() ?? "";
  String get botName => widget.conversation["name"]?.toString() ?? "Trợ lý AI";
  String get botAvatar => widget.conversation["avatarUrl"]?.toString() ?? "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      currentUserId = await _storage.read(key: "user_id");
      await loadMessages();
    } catch (e) {
      debugPrint("❌ Init ChatBotScreen failed: $e");
    }
  }

  DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  List<Map<String, dynamic>> _normalizeAndSortMessages(List<dynamic> data) {
    final normalized = data
        .map<Map<String, dynamic>>((msg) => Map<String, dynamic>.from(msg))
        .toList();

    normalized.sort((a, b) {
      final aTime = _parseCreatedAt(a["createdAt"]);
      final bTime = _parseCreatedAt(b["createdAt"]);
      return aTime.compareTo(bTime); // cũ -> mới
    });

    return normalized;
  }

  Future<void> loadMessages() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
      });

      final data = await _chatController.getMessages(conversationId);
      final loadedMessages = _normalizeAndSortMessages(data);

      if (!mounted) return;
      setState(() {
        messages = loadedMessages;
      });

      _scrollToBottom(jump: true);
    } catch (e) {
      debugPrint("❌ Load chatbot messages failed: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> handleSend({
    String? text,
    File? file,
    required String type,
  }) async {
    if (type != "text") return;

    final content = text?.trim() ?? "";
    if (content.isEmpty) return;

    final userId = currentUserId ?? await _storage.read(key: "user_id");
    if (userId == null || userId.isEmpty) return;

    _controller.clear();

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

    if (!mounted) return;
    setState(() {
      messages = [...messages, localMessage];
      messages.sort((a, b) {
        final aTime = _parseCreatedAt(a["createdAt"]);
        final bTime = _parseCreatedAt(b["createdAt"]);
        return aTime.compareTo(bTime);
      });
      isBotTyping = true;
    });

    _scrollToBottom();

    try {
      await _chatController.sendChatbotMessage(
        conversationId: conversationId,
        content: content,
      );

      if (!mounted) return;
      setState(() {
        final index = messages.indexWhere((m) => m["_id"] == localMessage["_id"]);
        if (index != -1) {
          messages[index]["status"] = "sent";
        }
      });

      _scrollToBottom();
      await _waitForBotReply();
    } catch (e) {
      debugPrint("❌ Send chatbot message failed: $e");

      if (!mounted) return;
      setState(() {
        final index = messages.indexWhere((m) => m["_id"] == localMessage["_id"]);
        if (index != -1) {
          messages[index]["status"] = "error";
        }
        isBotTyping = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> _waitForBotReply() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final data = await _chatController.getMessages(conversationId);
      final loadedMessages = _normalizeAndSortMessages(data);

      if (!mounted) return;
      setState(() {
        messages = loadedMessages;
        isBotTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("❌ Load bot reply failed: $e");

      if (!mounted) return;
      setState(() {
        isBotTyping = false;
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;

      if (jump) {
        _scrollController.jumpTo(maxScroll);
      } else {
        _scrollController.animateTo(
          maxScroll,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
              botAvatar.isNotEmpty ? NetworkImage(botAvatar) : null,
              child: botAvatar.isEmpty
                  ? const Icon(Icons.smart_toy, size: 18)
                  : null,
            ),
            const SizedBox(width: 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.55,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: const Radius.circular(6),
                ),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Hãy bắt đầu hỏi chatbot",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildMessageList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty && !isBotTyping) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      itemCount: messages.length + (isBotTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final msg = messages[index];
          return ChatMessage(message: msg);
        }

        return _buildTypingIndicator();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  Expanded(
                    child: _buildMessageList(),
                  ),
                  ChatInput(
                    controller: _controller,
                    onSend: handleSend,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(
              name: botName,
              avatar: botAvatar,
            ),
          ),
        ],
      ),
    );
  }
}