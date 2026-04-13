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
  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.otherUserId,
    required this.avatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final chatController = ChatController();
  final TextEditingController _controller = TextEditingController();
  final storage = FlutterSecureStorage();
  bool isLoading = false;

  List<Map<String, dynamic>> messages = [];
  StreamSubscription? _socketSub;
  @override
  void initState() {
    super.initState();

    loadMessages();

    _socketSub = SocketService().eventsStream.listen((event) {
      final eventName = event["event"];
      final data = event["data"];

      print("📩 Stream Event: $eventName | data: $data");

      if (!mounted) return;

      switch (eventName) {
        case "receive_message":
          final raw = data["message"];

            Map<String, dynamic> message;

            if (raw is String) {
              message = jsonDecode(raw); // ✅ convert string -> map
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

  void loadMessages() async {
    try {
      setState(() {
        isLoading = true;
      });
      final data = await chatController.getMessages(widget.conversationId);

      setState(() {
        messages = data.map((msg) => Map<String, dynamic>.from(msg)).toList();});
        isLoading = false;
      } catch (e) {
      isLoading = false;
      print("❌ Load message failed: $e");
    }
  }

  void handleSend({String? text, File? file, required String type}) async {
    final userId = await storage.read(key: "user_id");

    String content = text ?? "";
    String localPath = file?.path ?? "";

    /// 1. Optimistic UI (hiển thị ngay)
    setState(() {
      messages.insert(0, {
        "_id": "",
        "senderId": userId,
        "type": type,
        "content": type == "image" ? localPath : content,
        "attachments": [],
        "status": "sending",
        "isRecalled": false,
        "isDeleted": false,
        "createdAt": DateTime.now().toIso8601String(),
      });
    });

    final insertedIndex = 0;

    try {
      /// 2. Gọi API (GIỮ NGUYÊN BACKEND)
      final res = await chatController.sendMessage(
        conversationId: widget.conversationId,
        senderId: userId ?? "",
        content: type == "text" ? content : "",
        file: type == "image" ? file : null,
        type: type,
      );

      final message = res["result"];

      /// 4. Gửi socket realtime
      SocketService().emit("send_message", {
        "userId": userId,
        "toUserId": widget.otherUserId,
        "message": message,
      });

      /// 5. Update UI
      setState(() {
        messages[insertedIndex] = Map<String, dynamic>.from(message);
      });
    } catch (e) {
      /// 6. Error
      setState(() {
        messages[insertedIndex]["status"] = "error";
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
    _socketSub?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          /// 1. BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/images/chat_background.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// 2. CHAT AREA (LIST)
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
                  : ListView.builder(
                reverse: true,
                padding: const EdgeInsets.only(top: 80, bottom: 90),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];

                  return ChatMessage(
                    message: msg,
                    onLongPress: () => MessageOption.show(
                      context: context,
                      otherUserId: widget.otherUserId,
                      message: msg,
                      onSuccess: (result, messageId) {
                        setState(() {
                          final i = messages.indexWhere((m) => m["_id"] == messageId);
                          if (i == -1) return;

                          switch (result) {
                            case MessageOptionResult.deleted:
                              messages[i] = {...messages[i], "isDeleted": true};
                              break;
                            case MessageOptionResult.recalled:
                              messages[i] = {...messages[i], "isRecalled": true};
                              break;
                          }
                        });
                      },
                    )
                  );
                },
              ),
            ),
          ),

          /// 3. APP BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(
              name: widget.name,
              avatar: widget.avatar,
            ),
          ),

          /// 4. INPUT
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatInput(
              controller: _controller,
              onSend: handleSend,
            ),
          ),
        ],
      ),
    );
  }
}