import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatMessage extends StatefulWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onLongPress;

  const ChatMessage({
    super.key,
    required this.message,
    this.onLongPress,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  final _storage = const FlutterSecureStorage();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final id = await _storage.read(key: "user_id");
    setState(() {
      _currentUserId = id;
    });
  }

  bool get _isMe {
    final sender = widget.message["senderId"];
    final senderId = sender is Map ? sender["_id"] : sender;

    return senderId?.toString() == _currentUserId?.toString();
  }


  // ── Getters ──
  String get _type => widget.message["type"] ?? "text";
  String get _status => widget.message["status"] ?? "";
  bool get _recalled => widget.message["isRecalled"] ?? false;
  bool get _deleted => widget.message["isDeleted"] ?? false;

  DateTime? get _createdAt => widget.message["createdAt"] != null
      ? DateTime.tryParse(widget.message["createdAt"])
      : null;

  String get _content {
    if (_type == "image" || _type == "file") {
      final attachments = widget.message["attachments"] as List?;
      if (attachments != null && attachments.isNotEmpty) {
        return attachments[0]["url"] ?? "";
      }
      return widget.message["content"] ?? "";
    }
    return widget.message["content"] ?? "";
  }

  // ── Helpers ──
  String _formatTime(DateTime? dt) {
    if (dt == null) return "";
    final local = dt.toLocal();
    return "${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildStatusIcon() {
    if (!_isMe) return const SizedBox.shrink();
    switch (_status) {
      case "sending":
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case "sent":
        return const Icon(Icons.check, size: 14, color: Colors.white70);
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

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: GestureDetector(
          onLongPress: _recalled ? null : widget.onLongPress,
          child: _recalled
              ? _buildRecalledMessage()
              : _type == "image"
              ? _buildImageMessage(context)
              : _buildTextMessage(),
        ),
      ),
    );
  }

  // ── Recalled ──
  Widget _buildRecalledMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isMe
            ? Colors.blue.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded, size: 14,
              color: _isMe ? Colors.white54 : Colors.black38),
          const SizedBox(width: 6),
          Text(
            "Tin nhắn đã bị thu hồi",
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: _isMe ? Colors.white54 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  // ── Text ──
  Widget _buildTextMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: _isMe
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
              _content,
              style: TextStyle(
                color: _isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isMe ? Colors.white60 : Colors.black45,
                  ),
                ),
                const SizedBox(width: 4),
                _buildStatusIcon(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Image ──
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
                  child: Image.network(_content),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _content,
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
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(_createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              if (_isMe) ...[
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