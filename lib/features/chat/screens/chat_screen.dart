import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_appbar.dart';
import 'package:zalo_mobile_app/features/chat/screens/chat_message.dart';
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
  final TextEditingController _controller = TextEditingController();
  final storage = FlutterSecureStorage();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    loadMessages();

    // Lắng nghe tin nhắn mới
    SocketService().on("receive_message", (data) {
      if (mounted) {
        setState(() {
          messages.insert(0, {
            "message": data["message"],
            "isMe": false,
            "userId": data["userId"],
          });
        });
      }
    });
  }

  void loadMessages() async {
    final controller = ChatController();
    final userId = await storage.read(key: "user_id");

    try {
      final data = await controller.getMessages(widget.conversationId);

      setState(() {
        messages = data.map((msg) {
          return {
            "message": msg["message"],
            "isMe": msg["userId"] == userId,
          };
        }).toList();
      });
    } catch (e) {
      print("❌ Load message failed: $e");
    }
  }

  void handleSend(String text) async {
    final userId = await storage.read(key: "user_id");
    final newMessage = {
      "message": text,
      "isMe": true,
      "status": "sending",
    };

    setState(() {
      messages.insert(0, newMessage);
    });

    // Gửi lên backend qua Socket
    SocketService().emit("send_message", {
      "userId": userId,   // ID của mình
      "toUserId": widget.otherUserId,    // ID người nhận (toUserId ở backend)
      "message": text,
    });

    // gọi api send message
    final controller = ChatController();
    bool isSuccess = await controller.sendMessage(
      conversationId: widget.conversationId,
      senderId: userId ?? "",
      content: text,
    );

    // 3. Cập nhật lại trạng thái tin nhắn dựa trên kết quả API
    setState(() {
      newMessage["status"] = isSuccess ? "sent" : "error";
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _controller.dispose();
    SocketService().off("receive_message");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cho phép body tràn xuống dưới thanh điều hướng hệ thống (nếu cần)
      extendBody: true,
      body: Stack(
        children: [
          /// 1. Background (Dưới cùng)
          Positioned.fill(
            child: Image.asset(
              "assets/images/chat_background.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// 2. Chat Area (Ở giữa - Chiếm toàn bộ màn hình)
          Positioned.fill(
            child: ListView.builder(
              // Quan trọng: Thêm padding để tin nhắn đầu và cuối không bị AppBar/Input che mất
              reverse: true, // 👈 Dòng quan trọng nhất
              padding: const EdgeInsets.only(top: 80, bottom: 90),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatMessage(
                  message: msg["message"],
                  isMe: msg["isMe"],
                );
              },
            ),
          ),

          /// 3. AppBar (Ở trên cùng)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ChatAppBar(
              name: widget.name,
              avatar: widget.avatar,
            ),
          ),

          /// 4. Input (Ở dưới cùng)
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