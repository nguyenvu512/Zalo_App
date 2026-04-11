import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button_group.dart';
import 'package:zalo_mobile_app/features/profile_screen/controllers/profile_controller.dart';
import 'package:zalo_mobile_app/features/profile_screen/widgets/user_info_dialog.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late final ProfileController _controller;

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(storage: storage);
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final data = await _controller.fetchUserInfo();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Lỗi lấy thông tin: $e");
    }
  }

  Future<void> _handleSaveUser({
    required String fullName,
    required String gender,
    required String bio,
    required String phone,
    required String? dateOfBirth,
  }) async {
    final updated = await _controller.updateUser(
      fullName: fullName,
      gender: gender,
      bio: bio,
      phone: phone,
      dateOfBirth: dateOfBirth,
    );

    setState(() {
      userData = {
        ...?userData,
        ...updated,
      };
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cập nhật thông tin thành công")),
    );
  }

  Future<void> _handleLogout() async {
    await _controller.logout();

    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _showUserInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserInfoDialog(
        userData: userData,
        onSave: _handleSaveUser,
      ),
    );
  }

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

  Widget _buildStatusBadge() {
    final isOnline = userData?['isOnline'] == true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withOpacity(0.12)
            : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? "Online" : "Offline",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isOnline ? Colors.green : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    final bio = userData?['bio']?.toString().trim();

    if (bio == null || bio.isEmpty || bio == "null") {
      return Text(
        "Chưa cập nhật tiểu sử",
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      );
    }

    return Text(
      bio,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.grey[700],
        fontSize: 14,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 52,
                  backgroundImage: _buildAvatarProvider(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                userData?['fullName'] ?? "Chưa cập nhật",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _buildStatusBadge(),
              const SizedBox(height: 12),
              _buildBio(),
              const SizedBox(height: 24),
              MenuButtonGroup(
                buttons: [
                  MenuButton(
                    icon: Icons.add_a_photo,
                    label: "Đổi ảnh đại diện",
                    iconColor: const Color.fromARGB(255, 50, 149, 230),
                    textColor: const Color.fromARGB(255, 50, 149, 230),
                  ),
                  MenuButton(
                    icon: Icons.info,
                    label: "Thông tin cá nhân",
                    iconColor: const Color.fromARGB(255, 0, 248, 165),
                    showArrow: true,
                    onTap: _showUserInfoDialog,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              MenuButton(
                icon: Icons.person,
                label: "Trang cá nhân",
                iconColor: const Color.fromARGB(255, 50, 149, 230),
                showArrow: true,
              ),
              const SizedBox(height: 15),
              MenuButtonGroup(
                buttons: [
                  MenuButton(
                    icon: Icons.privacy_tip,
                    label: "Riêng tư & bảo mật",
                    iconColor: const Color.fromARGB(255, 85, 85, 85),
                  ),


                ],
              ),
              const SizedBox(height: 15),
              MenuButtonGroup(
                buttons: [
                  MenuButton(
                    icon: Icons.lock,
                    label: "Đổi mật khẩu",
                    iconColor: const Color.fromARGB(255, 255, 81, 0),
                  ),
                  MenuButton(
                    icon: Icons.logout,
                    label: "Đăng xuất",
                    iconColor: const Color.fromARGB(255, 255, 0, 0),
                    onTap: _handleLogout,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}