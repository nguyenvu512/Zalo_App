import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    final id = await _storage.read(key: "user_id");
    if (!mounted) return;
    setState(() {
      _currentUserId = id;
    });
  }

  bool get _isMe {
    final sender = widget.message["senderId"];
    final senderId = sender is Map ? sender["_id"] : sender;
    return senderId?.toString() == _currentUserId?.toString();
  }

  String get _type => widget.message["type"]?.toString() ?? "text";
  String get _status => widget.message["status"]?.toString() ?? "";
  bool get _recalled => widget.message["isRecalled"] == true;
  bool get _deleted => widget.message["isDeleted"] == true;

  DateTime? get _createdAt {
    final value = widget.message["createdAt"]?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String get _content {
    if (_type == "image" || _type == "file") {
      final attachments = widget.message["attachments"] as List?;
      if (attachments != null && attachments.isNotEmpty) {
        final first = attachments.first;
        if (first is Map && first["url"] != null) {
          return first["url"].toString();
        }
      }
    }
    return widget.message["content"]?.toString() ?? "";
  }

  bool get _isHtmlContent {
    final value = _content.trim().toLowerCase();
    return value.contains("<p") ||
        value.contains("<br") ||
        value.contains("<ul") ||
        value.contains("<ol") ||
        value.contains("<li") ||
        value.contains("<b") ||
        value.contains("<strong") ||
        value.contains("<i") ||
        value.contains("<em") ||
        value.contains("<div") ||
        value.contains("<span") ||
        value.contains("<h1") ||
        value.contains("<h2") ||
        value.contains("<h3");
  }

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
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);
      case "read":
        return const Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
      case "error":
        return const Icon(Icons.error_outline, size: 14, color: Colors.redAccent);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContentWidget() {
    if (!_isMe && (_type == "text" || _type == "mixed") && _isHtmlContent) {
      return Html(
        data: _content,
        style: {
          "html": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "body": Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            fontSize: FontSize(15),
            color: Colors.black,
          ),
          "p": Style(
            margin: Margins.only(bottom: 8),
            padding: HtmlPaddings.zero,
          ),
          "ul": Style(
            margin: Margins.only(left: 16, bottom: 8),
            padding: HtmlPaddings.zero,
          ),
          "ol": Style(
            margin: Margins.only(left: 16, bottom: 8),
            padding: HtmlPaddings.zero,
          ),
          "li": Style(
            margin: Margins.only(bottom: 6),
          ),
          "b": Style(fontWeight: FontWeight.w600),
          "strong": Style(fontWeight: FontWeight.w600),
          "i": Style(fontStyle: FontStyle.italic),
          "em": Style(fontStyle: FontStyle.italic),
          "h1": Style(
            margin: Margins.only(bottom: 8),
            fontSize: FontSize(22),
            fontWeight: FontWeight.bold,
          ),
          "h2": Style(
            margin: Margins.only(bottom: 8),
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
          ),
          "h3": Style(
            margin: Margins.only(bottom: 8),
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
          ),
        },
      );
    }

    return Text(
      _content,
      style: TextStyle(
        color: _isMe ? Colors.white : Colors.black,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        child: GestureDetector(
          onLongPress: _recalled ? null : widget.onLongPress,
          child: _recalled
              ? _buildRecalledMessage()
              : _type == "image"
              ? _buildImageMessage(context)
              : _type == "mixed"
              ? _buildMixedMessage(context) // 🔥 THÊM DÒNG NÀY
              : _buildTextMessage(context),
        ),
      ),
    );
  }

  Widget _buildRecalledMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isMe
            ? Colors.blue.withOpacity(0.25)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: _isMe ? Colors.white54 : Colors.black38,
          ),
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

  Widget _buildTextMessage(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _isMe
            ? Colors.blueAccent
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: _isMe ? const Radius.circular(6) : null,
          bottomLeft: !_isMe ? const Radius.circular(6) : null,
        ),
        border: !_isMe
            ? Border.all(color: Colors.black.withOpacity(0.05))
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 52, bottom: 14),
            child: _buildContentWidget(),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: _isMe ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (_isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment:
      _isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
          padding: const EdgeInsets.symmetric(horizontal: 6),
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
  Widget _buildMixedMessage(BuildContext context) {
    final attachments = widget.message["attachments"] as List? ?? [];
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: _isMe ? Colors.blueAccent : Colors.white,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: _isMe ? const Radius.circular(6) : null,
          bottomLeft: !_isMe ? const Radius.circular(6) : null,
        ),
        border: !_isMe
            ? Border.all(color: Colors.black.withOpacity(0.05))
            : null,
        boxShadow: !_isMe
            ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_content.trim().isNotEmpty) _buildContentWidget(),
          if (_content.trim().isNotEmpty && attachments.isNotEmpty)
            const SizedBox(height: 10),

          ...attachments.map((att) {
            if (att["type"] == "image" && att["url"] != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        backgroundColor: Colors.black,
                        child: InteractiveViewer(
                          child: Image.network(att["url"].toString()),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      att["url"].toString(),
                      width: maxWidth - 24,
                      height: 170,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          width: maxWidth - 24,
                          height: 170,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        width: maxWidth - 24,
                        height: 170,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(att["fileName"]?.toString() ?? "File"),
            );
          }),

          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(_createdAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _isMe ? Colors.white70 : Colors.black38,
                  ),
                ),
                if (_isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}