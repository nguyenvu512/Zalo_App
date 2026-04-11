import 'dart:ui';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isMe;

  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              constraints: const BoxConstraints(maxWidth: 250),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.blue.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}