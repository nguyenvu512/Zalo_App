import 'dart:ui';
import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12, // Tự động tránh phím ảo
          top: 12
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // Nền khung input trong suốt
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      hintStyle: TextStyle(color: Colors.black87.withOpacity(0.5)),
                      filled: true,
                      // Giảm độ đục của ô nhập liệu để thấy tin nhắn lướt qua
                      fillColor: Colors.white.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    onSend(text);
                    controller.clear();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.send, color: Colors.white.withOpacity(0.8), size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}