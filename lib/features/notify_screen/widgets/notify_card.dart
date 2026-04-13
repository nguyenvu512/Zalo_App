import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;
  final Function(Map<String, dynamic> noti)? onAccept;
  final Function(Map<String, dynamic> noti)? onReject;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onAccept,
    this.onReject,
  });

  String get id => notification["_id"]?.toString() ?? "";

  String get type => notification["type"]?.toString() ?? "";

  String get title {
    final value = notification["title"]?.toString();
    if (value == null || value.trim().isEmpty) return "Thông báo";
    return value;
  }

  String get content {
    final value = notification["content"]?.toString();
    if (value == null || value.trim().isEmpty) {
      return "Bạn có một thông báo mới";
    }
    return value;
  }

  bool get isRead => notification["isRead"] == true;

  Map<String, dynamic> get extraData {
    final raw = notification["data"];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  String get requesterId => extraData["requesterId"]?.toString() ?? "";

  String get requesterName {
    final value = extraData["requesterName"]?.toString();
    if (value == null || value.trim().isEmpty) return "Người dùng";
    return value;
  }

  String get friendshipId => extraData["friendshipId"]?.toString() ?? "";

  String get status => extraData["status"]?.toString() ?? "";

  // Lấy avatar url nếu backend có trả về
  String get avatarUrl {
    final value = extraData["requesterAvatar"]?.toString() ??
        notification["requesterAvatar"]?.toString() ??
        "";
    return value.trim();
  }

  // Fallback avatar free theo tên
  String get fallbackAvatarUrl {
    final encodedName = Uri.encodeComponent(requesterName);
    return "https://ui-avatars.com/api/?name=$encodedName&background=E3F2FD&color=1E88E5&size=128&bold=true";
  }

  String get createdAt {
    final value = notification["createdAt"]?.toString();
    if (value == null || value.trim().isEmpty) return "";

    try {
      final dt = DateTime.parse(value).toLocal();
      return "${_two(dt.hour)}:${_two(dt.minute)} ${_two(dt.day)}/${_two(dt.month)}/${dt.year}";
    } catch (_) {
      return value;
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  bool get canShowActions {
    return type == "friend_request" && status == "pending";
  }

  IconData get icon {
    switch (type) {
      case "friend_request":
        return Icons.person_add_alt_1_rounded;
      case "message":
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case "friend_request":
        return const Color(0xFF1E88E5);
      case "message":
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color get iconBg {
    switch (type) {
      case "friend_request":
        return const Color(0xFFE8F1FF);
      case "message":
        return const Color(0xFFEAFBF3);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Widget _buildAvatar() {
    final imageUrl = avatarUrl.isNotEmpty ? avatarUrl : fallbackAvatarUrl;

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE3F2FD),
      backgroundImage: NetworkImage(imageUrl),
      onBackgroundImageError: (_, __) {},
      child: avatarUrl.isEmpty
          ? null
          : null,
    );
  }

  Widget _buildFallbackLetterAvatar() {
    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE3F2FD),
      child: Text(
        requesterName.isNotEmpty ? requesterName[0].toUpperCase() : "?",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E88E5),
        ),
      ),
    );
  }

  Widget _buildAvatarSafe() {
    final imageUrl = avatarUrl.isNotEmpty ? avatarUrl : fallbackAvatarUrl;

    return ClipOval(
      child: Image.network(
        imageUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackLetterAvatar(),
      ),
    );
  }

  Widget _buildStatusChip() {
    if (status.isEmpty) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case "pending":
        bgColor = const Color(0xFFFFF4E5);
        textColor = const Color(0xFFF59E0B);
        label = "Đang chờ";
        break;
      case "accepted":
        bgColor = const Color(0xFFEAFBF3);
        textColor = const Color(0xFF10B981);
        label = "Đã chấp nhận";
        break;
      case "rejected":
        bgColor = const Color(0xFFFEECEC);
        textColor = const Color(0xFFEF4444);
        label = "Đã từ chối";
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!canShowActions) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              if (onAccept != null) {
                onAccept!(notification);
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Chấp nhận",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              if (onReject != null) {
                onReject!(notification);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(
                color: Color(0xFFFCA5A5),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Từ chối",
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isRead ? 0.82 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: isRead
                  ? null
                  : Border.all(
                color: const Color(0xFFD6E9FF),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildAvatarSafe(),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          icon,
                          size: 12,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildStatusChip(),
                          if (createdAt.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                createdAt,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (canShowActions) ...[
                        const SizedBox(height: 12),
                        _buildActionButtons(),
                      ],
                    ],
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