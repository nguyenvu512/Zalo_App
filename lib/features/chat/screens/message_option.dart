import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/common/popups/confirm_popup.dart';
import 'package:zalo_mobile_app/features/chat/controllers/chat_controller.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

enum MessageOptionResult { deleted, recalled }
enum _LoadingState { none, recalling, deleting }

class MessageOption extends StatefulWidget {
  final Map<String, dynamic> message;
  final void Function(MessageOptionResult result, String messageId) onSuccess;
  final String? otherUserId; // ✅ thêm dòng này

  const MessageOption({
    super.key,
    required this.message,
    required this.onSuccess,
    required this.otherUserId, // ✅
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> message,
    required String? otherUserId, // ✅ thêm
    required void Function(MessageOptionResult result, String messageId) onSuccess,
  }) {
    HapticFeedback.mediumImpact();

    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => MessageOption(
          message: message,
          onSuccess: onSuccess,
          otherUserId: otherUserId, // ✅ truyền vào
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
    setState(() {
      _currentUserId = id;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────

  String get _messageId =>
      widget.message["_id"] ?? widget.message["id"] ?? "";

  bool get isMe =>
      widget.message["senderId"]?["_id"] == _currentUserId;

  String get conversationId =>
      widget.message["conversationId"] ?? "";

  void _dismiss() => Navigator.of(context).pop();

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

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

  // ─────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 270),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.blue.withOpacity(0.45)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(content),
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
    final align =
    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

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