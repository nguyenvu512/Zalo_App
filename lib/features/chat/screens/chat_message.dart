import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessage extends StatefulWidget {
  final Map<String, dynamic> message;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;
  final bool isHighlighted;

  const ChatMessage({
    super.key,
    required this.message,
    this.onLongPress,
    this.onReplyTap,
    this.isHighlighted = false,
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
  bool get _isGroup => widget.message["chatType"] == "group";
  bool get _isForwarded => widget.message["isForwarded"] == true;

  String get _fileName {
    final attachments = widget.message["attachments"] as List?;
    if (attachments != null && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        return first["fileName"]?.toString() ?? "Tệp đính kèm";
      }
    }
    return "Tệp đính kèm";
  }

  String get _fileMimeType {
    final attachments = widget.message["attachments"] as List?;
    if (attachments != null && attachments.isNotEmpty) {
      final first = attachments.first;
      if (first is Map) {
        return first["mimeType"]?.toString() ?? "";
      }
    }
    return "";
  }

  Future<void> _openFile() async {
    final url = _content.trim();
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không mở được tệp")),
      );
    }
  }

  String get _senderAvatar {
    final sender = widget.message["senderId"];
    if (sender is Map) {
      return sender["avatarUrl"] ?? "";
    }
    return "";
  }

  String get _senderName {
    final sender = widget.message["senderId"];
    if (sender is Map) {
      return sender["fullName"] ?? "Người dùng";
    }
    return "Người dùng";
  }

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

    if (_type == "sticker") {
      return widget.message["content"] ?? "";
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

  Map<String, dynamic>? get _repliedMessage {
    final raw = widget.message["replyToMessageId"];
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  String _getReplyBlockText(Map<String, dynamic> replied) {
    if (replied["isRecalled"] == true) {
      return "Tin nhắn đã bị thu hồi";
    }

    final type = replied["type"]?.toString() ?? "text";

    switch (type) {
      case "image":
        return "📷 Hình ảnh";
      case "sticker":
        return "Sticker";
      case "file":
        final attachments = replied["attachments"];
        if (attachments is List && attachments.isNotEmpty) {
          final first = attachments.first;
          if (first is Map) {
            return first["fileName"]?.toString() ?? "Tệp đính kèm";
          }
        }
        return "Tệp đính kèm";
      case "text":
      default:
        final content = replied["content"]?.toString() ?? "";
        return content.isNotEmpty ? content : "Tin nhắn";
    }
  }

  List<Map<String, dynamic>> get _reactions {
    final raw = widget.message["reactions"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  bool get _hasReactions => _reactions.isNotEmpty;

  Map<String, List<Map<String, dynamic>>> _groupReactions() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final reaction in _reactions) {
      final emoji = reaction["emoji"]?.toString() ?? "";
      if (emoji.isEmpty) continue;

      grouped.putIfAbsent(emoji, () => []);
      grouped[emoji]!.add(reaction);
    }

    return grouped;
  }

  void _showReactionDetails() {
    final grouped = _groupReactions();
    if (grouped.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Cảm xúc",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: grouped.entries.expand((entry) {
                        final emoji = entry.key;
                        final users = entry.value;

                        return [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 6),
                            child: Text(
                              "$emoji  ${users.length}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          ...users.map((reaction) {
                            final user = reaction["userId"];
                            final fullName = user is Map
                                ? (user["fullName"]?.toString() ?? "Người dùng")
                                : "Người dùng";
                            final avatarUrl = user is Map
                                ? (user["avatarUrl"]?.toString() ?? "")
                                : "";

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                backgroundColor: Colors.grey[300],
                                child: avatarUrl.isEmpty
                                    ? const Icon(
                                  Icons.person,
                                  size: 18,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                              title: Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            );
                          }),
                        ];
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionSummaryInline({
    required Color bgColor,
    required Color textColor,
  }) {
    final grouped = _groupReactions();
    if (grouped.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _showReactionDetails,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: grouped.entries.map((entry) {
          final emoji = entry.key;
          final count = entry.value.length;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 12),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 3),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
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

  Widget _buildMetaRow({
    required Color timeColor,
    required Color reactionBgColor,
    required Color reactionTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildReactionSummaryInline(
              bgColor: reactionBgColor,
              textColor: reactionTextColor,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(_createdAt),
              style: TextStyle(
                fontSize: 11,
                color: timeColor,
              ),
            ),
            if (_isMe) ...[
              const SizedBox(width: 4),
              _buildStatusIcon(),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();

    Widget messageContent;

    if (_recalled) {
      messageContent = _buildRecalledMessage();
    } else {
      switch (_type) {
        case "image":
          messageContent = _buildImageMessage(context);
          break;
        case "sticker":
          messageContent = _buildStickerMessage(context);
          break;
        case "file":
          messageContent = _buildFileMessage();
          break;
        case "text":
        default:
          messageContent = _buildTextMessage();
          break;
      }
    }

    Widget body = GestureDetector(
      onLongPress: _recalled ? null : widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: widget.isHighlighted
            ? const EdgeInsets.all(4)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? Colors.yellow.withOpacity(0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: widget.isHighlighted
              ? Border.all(
            color: Colors.yellow.withOpacity(0.55),
            width: 1.2,
          )
              : null,
        ),
        child: messageContent,
      ),
    );

    if (_isGroup && !_isMe) {
      body = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage:
            _senderAvatar.isNotEmpty ? NetworkImage(_senderAvatar) : null,
            backgroundColor: Colors.grey[300],
            child: _senderAvatar.isEmpty
                ? const Icon(Icons.person, size: 20, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                  child: Text(
                    _senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                body,
              ],
            ),
          ),
        ],
      );
    }

    return Align(
      alignment: _isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        child: body,
      ),
    );
  }

  Widget _buildReplyBlock() {
    final replied = _repliedMessage;
    if (replied == null) return const SizedBox.shrink();

    final sender = replied["senderId"];
    String senderName = "Người dùng";

    if (sender is Map) {
      senderName = sender["fullName"]?.toString() ?? "Người dùng";
    }

    return GestureDetector(
      onTap: widget.onReplyTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: _isMe
              ? Colors.white.withOpacity(0.14)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: _isMe ? Colors.white70 : Colors.blue,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getReplyBlockText(replied),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage() {
    return GestureDetector(
      onTap: _openFile,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? Colors.yellow.withOpacity(0.35)
              : (_isMe
              ? Colors.blue.withOpacity(0.3)
              : Colors.white.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReplyBlock(),
            if (_isForwarded)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.forward,
                      size: 13,
                      color: _isMe ? Colors.white70 : Colors.black38,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Tin nhắn chuyển tiếp",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _isMe ? Colors.white70 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isMe
                        ? Colors.white.withOpacity(0.22)
                        : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.insert_drive_file_rounded,
                    color: _isMe ? Colors.white : Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _isMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_fileMimeType.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _fileMimeType,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _isMe ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildMetaRow(
              timeColor: _isMe ? Colors.white60 : Colors.black45,
              reactionBgColor: _isMe
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              reactionTextColor: _isMe ? Colors.white70 : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerMessage(BuildContext context) {
    const double stickerWidth = 140;

    return SizedBox(
      width: stickerWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReplyBlock(),
          if (_isForwarded)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.forward,
                    size: 13,
                    color: Colors.black38,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Tin nhắn chuyển tiếp",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
            child: Container(
              decoration: BoxDecoration(
                color: widget.isHighlighted
                    ? Colors.yellow.withOpacity(0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _content,
                  width: stickerWidth,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: stickerWidth,
                      height: stickerWidth,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: stickerWidth,
                    height: stickerWidth,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildMetaRow(
            timeColor: Colors.black45,
            reactionBgColor: Colors.black.withOpacity(0.06),
            reactionTextColor: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildRecalledMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? Colors.yellow.withOpacity(0.35)
            : (_isMe
            ? Colors.blue.withOpacity(0.3)
            : Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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

  Widget _buildTextMessage() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      constraints: const BoxConstraints(maxWidth: 250),
      decoration: BoxDecoration(
        color: widget.isHighlighted
            ? Colors.yellow.withOpacity(0.35)
            : (_isMe
            ? Colors.blue.withOpacity(0.3)
            : Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: _hasReactions ? 22 : 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReplyBlock(),
                if (_isForwarded)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forward,
                          size: 13,
                          color: _isMe ? Colors.white70 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Tin nhắn chuyển tiếp",
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _isMe ? Colors.white70 : Colors.black38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: _isMe ? Colors.white : Colors.black,
                      fontSize: 15,
                      height: 1.1,
                    ),
                    children: [
                      TextSpan(text: _content),
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: SizedBox(width: 56),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildMetaRow(
              timeColor: _isMe ? Colors.white60 : Colors.black45,
              reactionBgColor: _isMe
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.06),
              reactionTextColor: _isMe ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    const double imageWidth = 200;

    return SizedBox(
      width: imageWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReplyBlock(),
          if (_isForwarded)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.forward,
                    size: 13,
                    color: Colors.black38,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "Tin nhắn chuyển tiếp",
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
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
            child: Container(
              decoration: BoxDecoration(
                color: widget.isHighlighted
                    ? Colors.yellow.withOpacity(0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  _content,
                  width: imageWidth,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: imageWidth,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: imageWidth,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _buildMetaRow(
            timeColor: Colors.black45,
            reactionBgColor: Colors.black.withOpacity(0.06),
            reactionTextColor: Colors.black87,
          ),
        ],
      ),
    );
  }

}