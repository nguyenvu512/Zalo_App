import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onEditCover;

  const ProfileHeader({
    super.key,
    required this.userData,
    this.onEditCover,
  });

  ImageProvider _buildAvatarProvider() {
    final avatarUrl = userData?['avatarUrl'];
    final fullName = userData?['fullName'] ?? 'User';

    if (avatarUrl != null && avatarUrl.toString().trim().isNotEmpty) {
      return NetworkImage(avatarUrl);
    }

    return NetworkImage(
      "https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(fullName)}",
    );
  }

  ImageProvider _buildCoverProvider() {
    final coverUrl = userData?['coverUrl'];
    final fullName = userData?['fullName'] ?? 'User';

    if (coverUrl != null && coverUrl.toString().trim().isNotEmpty) {
      return NetworkImage(coverUrl);
    }

    return NetworkImage(
      "https://api.dicebear.com/9.x/shapes/png"
          "?seed=${Uri.encodeComponent(fullName)}"
          "&backgroundType=gradientLinear,solid"
          "&backgroundColor=3b82f6,06b6d4,8b5cf6,ec4899",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 210,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            image: DecorationImage(
              image: _buildCoverProvider(),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: onEditCover,
              icon: const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -52,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundImage: _buildAvatarProvider(),
            ),
          ),
        ),
      ],
    );
  }
}