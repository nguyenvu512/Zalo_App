import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/widgets/custom_text_field.dart';
import 'package:zalo_mobile_app/common/widgets/my_button.dart';
import 'package:zalo_mobile_app/features/contact_screen/controllers/contact_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final TextEditingController phoneController = TextEditingController();
  final ContactController controller =
  ContactController(storage: const FlutterSecureStorage());

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAddContact() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập số điện thoại")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await controller.findUserByPhone(phone);

      if (!mounted) return;

      if (user != null) {
        context.push(AppRoutes.profileDetail, extra: user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy người dùng")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87),
          ),
        ),
        centerTitle: true,
        title: const Text("Liên hệ mới"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              label: "Số điện thoại",
              controller: phoneController,
            ),
            const SizedBox(height: 24),
            MyButton(
              label: isLoading ? "Đang tìm..." : "Thêm",
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              onTap: isLoading ? null : _handleAddContact,
            ),
          ],
        ),
      ),
    );
  }
}