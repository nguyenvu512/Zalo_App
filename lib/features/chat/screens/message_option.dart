import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/common/popups/confirm_popup.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/features/chat/screens/forward_message_popup.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

enum MessageOptionResult { deleted, recalled, replied }

enum _LoadingState {
  none,
  recalling,
  deleting,
  forwarding,
  reacting,
  pinning,
  unpinning,
}

class MessageOption extends StatefulWidget {
  final Map<String, dynamic> message;
  final String conversationId;
  final void Function(MessageOptionResult result, String messageId) onSuccess;
  final String? otherUserId;

  const MessageOption({
    super.key,
    required this.message,
    required this.conversationId,
    required this.onSuccess,
    required this.otherUserId,
  });

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    required Map<String, dynamic> message,
    required String conversationId,
    required String? otherUserId,
    required void Function(MessageOptionResult result, String messageId)
    onSuccess,
  }) {
    HapticFeedback.mediumImpact();

    return Navigator.of(context).push<Map<String, dynamic>?>(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => MessageOption(
          message: message,
          conversationId: conversationId,
          onSuccess: onSuccess,
          otherUserId: otherUserId,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  State<MessageOption> createState() => _MessageOptionState();
}

class _MessageOptionState extends State<MessageOption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bubbleScale;
  late final Animation<double> _menuSlide;

  final _storage = const FlutterSecureStorage();
  final chatController = ChatController();

  final List<String> _quickReactions = ["👍", "❤️", "😂", "😮", "😢", "🔥"];

  String? _currentUserId;
  _LoadingState _loadingState = _LoadingState.none;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initUser();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bubbleScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
    );

    _menuSlide = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    );

    _ctrl.forward();
  }

  Future<void> _initUser() async {
    final id = await _storage.read(key: "user_id");
    if (!mounted) return;
    setState(() {
      _currentUserId = id;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _messageId => widget.message["_id"] ?? widget.message["id"] ?? "";

  bool get isMe => widget.message["senderId"]?["_id"] == _currentUserId;

  bool get _isPinned {
    final raw = widget.message["isPinned"];
    if (raw is bool) return raw;
    return false;
  }

  String get conversationId => widget.conversationId;

  void _dismiss() => Navigator.of(context).pop();

  Future<void> _handleReply() async {
    if (_loadingState != _LoadingState.none) return;

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSuccess(MessageOptionResult.replied, _messageId);
    }
  }

  Future<void> _handleReact(String emoji) async {
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.reacting;
      _errorText = null;
    });

    try {
      final res = await chatController.reactMessage(
        messageId: _messageId,
        emoji: emoji,
      );

      final updatedMessage = Map<String, dynamic>.from(res["result"]);

      if (mounted) {
        Navigator.of(context).pop({
          "action": "reaction",
          "message": updatedMessage,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingState = _LoadingState.none;
        _errorText = "Thả cảm xúc thất bại";
      });
    }
  }

  Future<void> _handlePin() async {
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.pinning;
      _errorText = null;
    });

    try {
      final res = await chatController.pinMessage(
        conversationId: conversationId,
        messageId: _messageId,
      );

      final pinned = (res["result"]["pinnedMessages"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        Navigator.of(context).pop({
          "action": "pin",
          "pinnedMessages": pinned,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingState = _LoadingState.none;
        _errorText = "Ghim tin nhắn thất bại";
      });
    }
  }

  Future<void> _handleUnpin() async {
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.unpinning;
      _errorText = null;
    });

    try {
      final res = await chatController.unpinMessage(
        conversationId: conversationId,
        messageId: _messageId,
      );

      final pinned = (res["result"]["pinnedMessages"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (mounted) {
        Navigator.of(context).pop({
          "action": "unpin",
          "pinnedMessages": pinned,
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingState = _LoadingState.none;
        _errorText = "Bỏ ghim thất bại";
      });
    }
  }

  Future<void> _handleForward() async {
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.forwarding;
      _errorText = null;
    });

    try {
      await ForwardMessagePopup.show(
        context: context,
        message: widget.message,
        currentConversationId: conversationId,
      );

      if (mounted) {
        setState(() {
          _loadingState = _LoadingState.none;
        });
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = _LoadingState.none;
          _errorText = "Không thể mở chuyển tiếp";
        });
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleRecall() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: "Xác nhận",
      message: "Bạn có chắc muốn thu hồi tin nhắn này không?",
      confirmLabel: "Thu hồi",
    );

    if (!confirmed || _loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.recalling;
      _errorText = null;
    });

    try {
      await chatController.revokeMessage(_messageId);

      SocketService().emit("recall_message", {
        "toUserId": widget.otherUserId,
        "messageId": _messageId,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(MessageOptionResult.recalled, _messageId);
      }
    } catch (e) {
      setState(() {
        _loadingState = _LoadingState.none;
        _errorText = "Thu hồi thất bại, thử lại";
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: "Xác nhận",
      message: "Bạn có chắc muốn xóa tin nhắn này không?",
      confirmLabel: "Xóa",
    );

    if (!confirmed || _loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.deleting;
      _errorText = null;
    });

    try {
      await chatController.deleteMessage(_messageId);

      SocketService().emit("delete_message", {
        "messageId": _messageId,
        "toUserId": widget.otherUserId,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(MessageOptionResult.deleted, _messageId);
      }
    } catch (e) {
      setState(() {
        _loadingState = _LoadingState.none;
        _errorText = "Xóa thất bại, thử lại";
      });
    }
  }

  Widget _buildBubblePreview() {
    final type = widget.message["type"] ?? "text";
    final content = widget.message["content"] ?? "";
    final attachments = widget.message["attachments"];

    if (type == "image") {
      String? imageUrl;

      if (attachments is List && attachments.isNotEmpty) {
        imageUrl = attachments[0]["url"];
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        return Container(
          width: 220,
          height: 160,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 160,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    if (type == "sticker") {
      final String? imageUrl = content;

      if (imageUrl == null || imageUrl.isEmpty) {
        return Container(
          width: 220,
          height: 160,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 220,
            height: 160,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    if (type == "file") {
      String fileName = "Tệp đính kèm";

      if (attachments is List && attachments.isNotEmpty) {
        final first = attachments.first;
        if (first is Map<String, dynamic>) {
          fileName = first["fileName"]?.toString() ?? "Tệp đính kèm";
        }
      }

      return Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe
              ? Colors.blue.withOpacity(0.45)
              : Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 270),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.45)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        content.toString(),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildReactionBar() {
    final blocked = _loadingState != _LoadingState.none;

    return ClipRect(
      child: ScaleTransition(
        scale: _bubbleScale,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._quickReactions.map((emoji) {
                  return GestureDetector(
                    onTap: blocked ? null : () => _handleReact(emoji),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: blocked ? 0.45 : 1,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                }),
                if (_loadingState == _LoadingState.reacting)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isMuted = false,
    bool isLoading = false,
  }) {
    final color = isDestructive
        ? Colors.red[600]!
        : isMuted
        ? Colors.black38
        : Colors.black87;

    final blocked = _loadingState != _LoadingState.none && !isMuted;

    return InkWell(
      onTap: blocked ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 19, color: color),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (isMe)
                _buildMenuRow(
                  icon: Icons.undo,
                  label: "Thu hồi",
                  onTap: _handleRecall,
                  isLoading: _loadingState == _LoadingState.recalling,
                ),
              if (isMe)
                _buildMenuRow(
                  icon: Icons.delete_outline,
                  label: "Xóa",
                  onTap: _handleDelete,
                  isDestructive: true,
                  isLoading: _loadingState == _LoadingState.deleting,
                ),
              _buildMenuRow(
                icon: Icons.reply,
                label: "Trả lời",
                onTap: _handleReply,
              ),
              _buildMenuRow(
                icon: _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                label: _isPinned ? "Bỏ ghim tin nhắn" : "Ghim tin nhắn",
                onTap: _isPinned ? _handleUnpin : _handlePin,
                isLoading: _isPinned
                    ? _loadingState == _LoadingState.unpinning
                    : _loadingState == _LoadingState.pinning,
              ),
              _buildMenuRow(
                icon: Icons.forward,
                label: "Chuyển tiếp",
                onTap: _handleForward,
                isLoading: _loadingState == _LoadingState.forwarding,
              ),
              _buildMenuRow(
                icon: Icons.close,
                label: "Hủy",
                onTap: _dismiss,
                isMuted: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _loadingState != _LoadingState.none ? null : _dismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: align,
                  children: [
                    const Spacer(),
                    ScaleTransition(
                      scale: _bubbleScale,
                      alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: _buildBubblePreview(),
                    ),
                    const SizedBox(height: 14),
                    _buildReactionBar(),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _menuSlide,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 20 * (1 - _menuSlide.value)),
                        child: Opacity(
                          opacity: _menuSlide.value,
                          child: child,
                        ),
                      ),
                      child: SizedBox(
                        width: 220,
                        child: _buildMenu(),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}