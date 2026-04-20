import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageChatBot extends StatelessWidget {
  final Map<String, dynamic> message;
  final String botAvatar;
  final String botName;

  const MessageChatBot({
    super.key,
    required this.message,
    this.botAvatar = "",
    this.botName = "Trợ lý AI",
  });

  String get _type => message["type"]?.toString() ?? "text";
  String get _content => message["content"]?.toString() ?? "";
  String get _status => message["status"]?.toString() ?? "";
  bool get _recalled => message["isRecalled"] == true;
  bool get _deleted => message["isDeleted"] == true;
  bool get _isForwarded => message["isForwarded"] == true;

  DateTime? get _createdAt {
    final value = message["createdAt"]?.toString();
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<Map<String, dynamic>> get _attachments {
    final raw = message["attachments"];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  Map<String, dynamic>? get _repliedMessage {
    final raw = message["replyToMessageId"];
    if (raw is Map<String, dynamic>) return raw;
    return null;
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
      case "mixed":
        final content = replied["content"]?.toString() ?? "";
        if (content.trim().isNotEmpty) return content;
        return "Tin nhắn";
      case "text":
      default:
        final content = replied["content"]?.toString() ?? "";
        return content.isNotEmpty ? content : "Tin nhắn";
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Liên kết không hợp lệ")),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không mở được liên kết")),
      );
    }
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundImage: botAvatar.isNotEmpty ? NetworkImage(botAvatar) : null,
      backgroundColor: Colors.grey[300],
      child: botAvatar.isEmpty
          ? const Icon(
        Icons.smart_toy,
        size: 20,
        color: Colors.white,
      )
          : null,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        botName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildForwardedLabel() {
    if (!_isForwarded) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTime() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(_createdAt),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(
                _status == "error"
                    ? Icons.error_outline
                    : Icons.check,
                size: 12,
                color: _status == "error" ? Colors.redAccent : Colors.black38,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBlock() {
    final replied = _repliedMessage;
    if (replied == null) return const SizedBox.shrink();

    String senderName = botName;
    final sender = replied["senderId"];
    if (sender is Map) {
      senderName = sender["fullName"]?.toString() ?? botName;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getReplyBlockText(replied),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecalledMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.block_rounded,
          size: 14,
          color: Colors.black38,
        ),
        SizedBox(width: 6),
        Text(
          "Tin nhắn đã bị thu hồi",
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildTextOrHtml(BuildContext context) {
    if (_isHtmlContent) {
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
            color: Colors.black87,
            lineHeight: const LineHeight(1.35),
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
          "b": Style(fontWeight: FontWeight.w700),
          "strong": Style(fontWeight: FontWeight.w700),
          "i": Style(fontStyle: FontStyle.italic),
          "em": Style(fontStyle: FontStyle.italic),
          "h1": Style(
            fontSize: FontSize(22),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 8),
          ),
          "h2": Style(
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 8),
          ),
          "h3": Style(
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            margin: Margins.only(bottom: 8),
          ),
        },
        onLinkTap: (url, attributes, element) {
          if (url != null && url.isNotEmpty) {
            _openUrl(context, url);
          }
        },
      );
    }

    return Text(
      _content,
      style: const TextStyle(
        fontSize: 15,
        height: 1.35,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    String imageUrl = _content;

    if (_attachments.isNotEmpty && _attachments.first["url"] != null) {
      imageUrl = _attachments.first["url"].toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_content.trim().isNotEmpty &&
            !_content.startsWith("http://") &&
            !_content.startsWith("https://"))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTextOrHtml(context),
          ),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                insetPadding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 200,
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              width: 220,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 220,
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: 220,
                height: 180,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFile(BuildContext context) {
    String fileUrl = _content;
    String fileName = "Tệp đính kèm";
    String mimeType = "";

    if (_attachments.isNotEmpty) {
      final first = _attachments.first;
      fileUrl = first["url"]?.toString() ?? fileUrl;
      fileName = first["fileName"]?.toString() ?? fileName;
      mimeType = first["mimeType"]?.toString() ?? "";
    }

    return GestureDetector(
      onTap: fileUrl.isEmpty ? null : () => _openUrl(context, fileUrl),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.insert_drive_file_rounded,
                color: Colors.black87,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mimeType.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      mimeType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMixed(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_content.trim().isNotEmpty) _buildTextOrHtml(context),
        if (_content.trim().isNotEmpty && _attachments.isNotEmpty)
          const SizedBox(height: 10),
        ..._attachments.map((att) {
          final type = att["type"]?.toString() ?? "";
          final url = att["url"]?.toString() ?? "";

          if (type == "image" && url.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.black,
                      insetPadding: const EdgeInsets.all(12),
                      child: InteractiveViewer(
                        child: Image.network(url),
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    url,
                    width: maxWidth,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: maxWidth,
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: maxWidth,
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: url.isEmpty ? null : () => _openUrl(context, url),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        att["fileName"]?.toString() ?? "Tệp đính kèm",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMessageBody(BuildContext context) {
    if (_recalled) {
      return _buildRecalledMessage();
    }

    switch (_type) {
      case "image":
        return _buildImage(context);
      case "file":
        return _buildFile(context);
      case "mixed":
        return _buildMixed(context);
      case "text":
      default:
        return _buildTextOrHtml(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomLeft: const Radius.circular(6),
                  ),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildReplyBlock(),
                    _buildForwardedLabel(),
                    _buildMessageBody(context),
                    _buildTime(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}