import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/profile_screen/controllers/profile_controller.dart';

class ProfileDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileDetailScreen({super.key, required this.user});

  String getAvatarUrl(String name) {
    return "https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(name)}";
  }

  String getCoverUrl(String name) {
    final seed = name.codeUnits.fold(0, (a, b) => a + b) % 100000;
    return "https://picsum.photos/seed/$seed/900/400";
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> userData =
        (user["user"] as Map<String, dynamic>?) ?? {};

    final String relationship = user["relationship"]?.toString() ?? "none";

    final String fullName =
    (userData["fullName"]?.toString().trim().isNotEmpty ?? false)
        ? userData["fullName"].toString()
        : "Không có tên";

    final String bio =
    (userData["bio"]?.toString().trim().isNotEmpty ?? false)
        ? userData["bio"].toString()
        : "Chưa có mô tả";

    final String avatarUrl =
    (userData["avatarUrl"]?.toString().trim().isNotEmpty ?? false)
        ? userData["avatarUrl"].toString()
        : getAvatarUrl(fullName);

    final String coverUrl =
    (userData["coverUrl"]?.toString().trim().isNotEmpty ?? false)
        ? userData["coverUrl"].toString()
        : getCoverUrl(fullName);

    final String? friendId =
        userData["_id"]?.toString() ?? userData["id"]?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4FACFE), Color(0xFF1E88E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.black.withOpacity(0.08),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: -56,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.network(
                            avatarUrl,
                            width: 112,
                            height: 112,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 112,
                                height: 112,
                                color: const Color(0xFFE3F2FD),
                                alignment: Alignment.center,
                                child: Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF1E88E5),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Giới thiệu",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.6,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: mở chat
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text(
                          "Nhắn tin",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: relationship == "none"
                            ? () async {
                          if (friendId == null || friendId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Không tìm thấy id người dùng"),
                              ),
                            );
                            return;
                          }

                          try {
                            final controller = ProfileController(
                              storage: const FlutterSecureStorage(),
                            );

                            await controller.sendFriendRequest(friendId);

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Đã gửi lời mời kết bạn"),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Lỗi: $e")),
                              );
                            }
                          }
                        }
                            : null,
                        icon: Icon(
                          relationship == "friend"
                              ? Icons.check_circle_outline
                              : relationship == "pending"
                              ? Icons.schedule
                              : Icons.person_add_alt_1_rounded,
                        ),
                        label: Text(
                          relationship == "friend"
                              ? "Bạn bè"
                              : relationship == "pending"
                              ? "Đã gửi"
                              : "Kết bạn",
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}