import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/widgets/menu_button.dart';
import 'dart:convert';

import 'package:zalo_mobile_app/common/widgets/menu_button_group.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    // try {
      // final prefs = await SharedPreferences.getInstance();
      // final userId = prefs.getString('userId');
      // final token = prefs.getString('token');

    //   final url = Uri.parse('http://localhost:5000/api/user/$userId');
    //   final response = await http.get(url, headers: {
    //     'Authorization': 'Bearer $token', // Gửi kèm token để authenticate
    //   });
    //
    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     setState(() {
    //       // Lấy đúng theo cấu trúc bạn gửi: result -> result
    //       userData = data['result']['result'];
    //       isLoading = false;
    //     });
    //   }
    // } catch (e) {
    //   print("Lỗi lấy thông tin: $e");
    // }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              // 1. Hiển thị Ảnh đại diện
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: (userData?['avatarUrl'] != null && userData!['avatarUrl'].isNotEmpty)
                      ? NetworkImage(userData!['avatarUrl'])
                      : const AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
              ),

              const SizedBox(height: 8),
              
              // 2. Hiển thị Tên
              Text(
                userData?['fullName'] ?? "Chưa cập nhật",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 25),

              // Nút Đổi ảnh đại diện
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
                  MenuButton(
                    icon: Icons.color_lens,
                    label: "Giao diện",
                    iconColor: const Color.fromARGB(255, 110, 97, 223),
                  ),
                  MenuButton(
                    icon: Icons.language,
                    label: "Ngôn ngữ",
                    iconColor: const Color.fromARGB(255, 255, 145, 178),
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
                  ),
                ],
              ),
            ],
        ),
      )
    );
  }
  // Dialog đổi mật khẩu nhanh
  // void _showChangePasswordDialog(BuildContext context) {
  //   final oldPassController = TextEditingController();
  //   final newPassController = TextEditingController();
  //   final confirmPassController = TextEditingController(); // Thêm trường confirm

  //   bool isSubmitting = false; // Trạng thái loading khi gọi API

  //   showDialog(
  //     context: context,
  //     // Dùng StatefulBuilder để có thể gọi setState() cập nhật UI CỦA RIÊNG CÁI DIALOG
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setState) {
  //         return AlertDialog(
  //           title: const Text("Đổi mật khẩu"),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               TextField(
  //                 controller: oldPassController,
  //                 decoration: const InputDecoration(labelText: "Mật khẩu cũ"),
  //                 obscureText: true,
  //               ),
  //               TextField(
  //                 controller: newPassController,
  //                 decoration: const InputDecoration(labelText: "Mật khẩu mới"),
  //                 obscureText: true,
  //               ),
  //               TextField(
  //                 controller: confirmPassController,
  //                 decoration: const InputDecoration(labelText: "Nhập lại mật khẩu mới"),
  //                 obscureText: true,
  //               ),
  //             ],
  //           ),
  //           actions: [
  //             TextButton(
  //               // Nếu đang gọi API thì khóa nút Hủy
  //               onPressed: isSubmitting ? null : () => Navigator.pop(context),
  //               child: const Text("Hủy")
  //             ),
  //             ElevatedButton(
  //               onPressed: isSubmitting ? null : () async {
  //                 final oldPass = oldPassController.text.trim();
  //                 final newPass = newPassController.text.trim();
  //                 final confirmPass = confirmPassController.text.trim();

  //                 // 1. Validate form cơ bản
  //                 if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
  //                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin!")));
  //                   return;
  //                 }
  //                 if (newPass != confirmPass) {
  //                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mật khẩu mới không khớp!")));
  //                   return;
  //                 }

  //                 // Bật trạng thái loading trên nút bấm
  //                 setState(() => isSubmitting = true);

  //                 try {
  //                   // 2. Lấy userId và token từ Local Storage
  //                   final prefs = await SharedPreferences.getInstance();
  //                   final userId = prefs.getString('userId');
  //                   final token = prefs.getString('token');

  //                   // LƯU Ý: Nếu chạy máy ảo Android thì đổi localhost thành 10.0.2.2
  //                   final url = Uri.parse('http://localhost:5000/api/user/change-password');

  //                   // 3. Gọi API
  //                   final response = await http.patch(
  //                     url,
  //                     headers: {
  //                       'Content-Type': 'application/json',
  //                       'Authorization': 'Bearer $token', // Gửi kèm token bảo mật
  //                     },
  //                     body: jsonEncode({
  //                       'userId': userId, // Gửi đúng cấu trúc API bạn yêu cầu
  //                       'oldPassword': oldPass,
  //                       'newPassword': newPass,
  //                       'confirmPassword': confirmPass,
  //                     }),
  //                   );

  //                   if (!context.mounted) return;

  //                   // 4. Xử lý kết quả
  //                   if (response.statusCode == 200) {
  //                     final data = jsonDecode(response.body);

  //                     if (data['code'] == 1000) {
  //                       Navigator.pop(context); // Đóng Dialog
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         const SnackBar(content: Text("Đổi mật khẩu thành công!"), backgroundColor: Colors.green),
  //                       );
  //                     } else {
  //                       // Sai mật khẩu cũ hoặc lỗi từ server
  //                       ScaffoldMessenger.of(context).showSnackBar(
  //                         SnackBar(content: Text(data['message'] ?? "Lỗi đổi mật khẩu")),
  //                       );
  //                     }
  //                   } else {
  //                     ScaffoldMessenger.of(context).showSnackBar(
  //                       SnackBar(content: Text("Lỗi server: HTTP ${response.statusCode}")),
  //                     );
  //                   }
  //                 } catch (e) {
  //                   if (!context.mounted) return;
  //                   ScaffoldMessenger.of(context).showSnackBar(
  //                     SnackBar(content: Text("Lỗi kết nối: $e")),
  //                   );
  //                 } finally {
  //                   // Tắt trạng thái loading (chỉ tắt khi dialog chưa bị đóng)
  //                   if (context.mounted) {
  //                     setState(() => isSubmitting = false);
  //                   }
  //                 }
  //               },
  //               // Hiển thị vòng xoay loading hoặc chữ Cập nhật
  //               child: isSubmitting
  //                   ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
  //                   : const Text("Cập nhật"),
  //             ),
  //           ],
  //         );
  //       }
  //     ),
    // );
  // }
}