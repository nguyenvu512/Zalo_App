import 'package:flutter/material.dart';

class ConversationItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final String type;
  final int unreadCount;
  final VoidCallback onTap;

  const ConversationItem({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.lastMessage,
    required this.time,
    required this.type,
    required this.onTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            /// Avatar
            CircleAvatar(
              radius: 25,
              backgroundImage: (type != 'group' && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: type == 'group'
                  ? const Icon(Icons.group)
                  : avatarUrl.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            /// Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name + Time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? const Color(0xFF111111)
                                : const Color(0xFF666666),
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// Last message + unread badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unreadCount > 0
                                ? const Color(0xFF333333)
                                : const Color(0xFF999999),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 3, 133, 10),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}