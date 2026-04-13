import 'dart:ui';
import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isMe;
  final String type; // text | image | file
  final String? status;
  final DateTime? createdAt;
  final VoidCallback? onLongPress;
  final bool recalled;
  final bool isDeleted;

  const ChatMessage({
    super.key,
    required this.message,
    required this.isMe,
    required this.type,
    this.status,
    this.createdAt,
    this.onLongPress,   // ← thêm
    required this.recalled,   // ← thêm
    this.isDeleted = false,
  });

  /// =========================
  /// MAIN BUILD
  /// =========================
  @override
  Widget build(BuildContext context) {
    if (isDeleted) return const SizedBox.shrink();  // ← không render gì

    final isImage = type == "image";

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: GestureDetector(
          onLongPress: recalled ? null : onLongPress,  // recalled thì ko cho long press
          child: recalled
              ? _buildRecalledMessage()
              : isImage
              ? _buildImageMessage(context)
              : _buildTextMessage(),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final local = dt.toLocal();
    return "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildStatusIcon() {
    if (!isMe) return const SizedBox.shrink();

    switch (status) {
      case "sending":
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case "sent":
        return const Icon(Icons.check, size: 14, color: Colors.white70,);
      case "delivered":
        return const Icon(Icons.done_all, size: 14);
      case "read":
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);
      case "error":
        return const Icon(Icons.error_outline, size: 14, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }

  // Thêm widget riêng cho recalled
  Widget _buildRecalledMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: isMe ? Colors.white54 : Colors.black38,
          ),
          const SizedBox(width: 6),
          Text(
            "Tin nhắn đã bị thu hồi",
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: isMe ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// TEXT MESSAGE (GIỮ UI CŨ)
  /// =========================
  Widget _buildTextMessage() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 48, bottom: 14),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),

              /// TIME + STATUS
              Positioned(
                bottom: 0,
                right: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildStatusIcon(),
                  ],
                ),
              ),
            ],
          ),
        // ),
      // ),
    );
  }

  /// =========================
  /// IMAGE MESSAGE
  /// =========================
  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                child: InteractiveViewer(
                  child: Image.network(message),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              message,
              width: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 200,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 200,
                height: 150,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),

        const SizedBox(height: 4),

        /// TIME + STATUS (RIGHT ALIGN + PADDING 6)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black45,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}