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
  final bool isMe;
  final String conversationId;
  final ChatController chatController;
  final String otherUserId;
  final void Function(MessageOptionResult result, String messageId) onSuccess;

  const MessageOption({
    super.key,
    required this.message,
    required this.isMe,
    required this.conversationId,
    required this.chatController,
    required this.onSuccess,
    required this.otherUserId,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> message,
    required bool isMe,
    required String conversationId,
    required ChatController chatController,
    required String otherUserId,
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
        pageBuilder: (ctx, _, __) => MessageOption(
          message: message,
          isMe: isMe,
          conversationId: conversationId,
          chatController: chatController,
          otherUserId: otherUserId,
          onSuccess: onSuccess,
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

  _LoadingState _loadingState = _LoadingState.none;
  String? _errorText;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() => Navigator.of(context).pop();

  String get _messageId => widget.message["_id"] ?? widget.message["id"] ?? "";

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
    if (!confirmed) return;
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.recalling;
      _errorText = null;
    });

    try {
      await widget.chatController.revokeMessage(_messageId);

      SocketService().emit("recall_message", {
        "messageId": _messageId,
        "toUserId": widget.otherUserId,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(MessageOptionResult.recalled, _messageId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = _LoadingState.none;
          _errorText = "Thu hồi thất bại, thử lại";
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: "Xác nhận",
      message: "Bạn có chắc muốn xóa này không?",
      confirmLabel: "Xóa",
    );
    if (!confirmed) return;
    if (_loadingState != _LoadingState.none) return;

    setState(() {
      _loadingState = _LoadingState.deleting;
      _errorText = null;
    });

    try {
      await widget.chatController.deleteMessage(_messageId);

      SocketService().emit("delete_message", {
        "messageId": _messageId,
        "toUserId": widget.otherUserId,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSuccess(MessageOptionResult.deleted, _messageId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingState = _LoadingState.none;
          _errorText = "Xóa thất bại, thử lại";
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // Bubble preview
  // ─────────────────────────────────────────────

  Widget _buildBubblePreview() {
    final type = widget.message["type"] ?? "text";
    final content = widget.message["content"] ?? "";

    if (type == "image") {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          content,
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
        color: widget.isMe
            ? Colors.blue.withOpacity(0.45)
            : Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 16,
          color: widget.isMe ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Menu
  // ─────────────────────────────────────────────

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  color: Colors.red.withOpacity(0.08),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(fontSize: 13, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (widget.isMe) ...[
                _buildMenuRow(
                  icon: Icons.undo_rounded,
                  label: "Thu hồi",
                  onTap: _handleRecall,
                  isLoading: _loadingState == _LoadingState.recalling,
                ),
                const Divider(height: 0.5, thickness: 0.5, color: Colors.black12),
              ],

              if (widget.isMe) ...[
                _buildMenuRow(
                  icon: Icons.delete_outline_rounded,
                  label: "Xóa",
                  onTap: _handleDelete,
                  isDestructive: true,
                  isLoading: _loadingState == _LoadingState.deleting,
                ),
              ],

              const Divider(height: 0.5, thickness: 0.5, color: Colors.black12),

              _buildMenuRow(
                icon: Icons.close_rounded,
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

    final bool blocked = _loadingState != _LoadingState.none && !isMuted;

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
            Text(
              label,
              style: TextStyle(fontSize: 15, color: color),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final align =
    widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _loadingState != _LoadingState.none ? null : _dismiss,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            width: double.infinity,
            height: double.infinity,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: align,
                  children: [
                    const Spacer(),

                    ScaleTransition(
                      scale: _bubbleScale,
                      alignment: widget.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: _buildBubblePreview(),
                    ),

                    const SizedBox(height: 20),

                    AnimatedBuilder(
                      animation: _menuSlide,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, 20 * (1 - _menuSlide.value)),
                        child: Opacity(
                          opacity: _menuSlide.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                      child: SizedBox(
                        width: 220,
                        child: GestureDetector(
                          onTap: () {},
                          child: _buildMenu(),
                        ),
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