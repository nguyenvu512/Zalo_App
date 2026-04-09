import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/helper/snackbar_helper.dart';
import 'package:zalo_mobile_app/common/popups/custom_dialog.dart';
import 'package:zalo_mobile_app/common/widgets/custom_text_field.dart';
import 'package:zalo_mobile_app/common/widgets/my_button.dart';
import 'package:zalo_mobile_app/features/auth/controllers/auth_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class ConfirmRegisterDialog extends StatefulWidget {
  final String email;

  const ConfirmRegisterDialog({super.key, required this.email});

  @override
  State<ConfirmRegisterDialog> createState() => _ConfirmRegisterDialogState();
}

class _ConfirmRegisterDialogState extends State<ConfirmRegisterDialog> {
  final AuthController _authController = AuthController();

  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;

  void _verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.isEmpty) {
      CustomDialog.show(context: context, message: "Please enter OPT");
      return;
    }

    setState(() => isLoading = true);

    final error = await _authController.verifyEmail(
        email: widget.email,
        otp: otpController.text.trim(),
    );

    setState(() => isLoading = false);

    if (error != null) {
      CustomDialog.show(context: context, message: error);
    } else {
    //   đúng otp
      setState(() => isLoading = false);
      Navigator.pop(context); // ✅ đóng dialog OTP
      SnackBarHelper.show(context, "Verify success");
      context.go(AppRoutes.login);
    }
  }

  void _resendOtp() async {
    setState(() => isLoading = true);

    final error = await _authController.resendOtp(
      email: widget.email,
    );
    setState(() => isLoading = false);

    if (error != null) {
      CustomDialog.show(context: context, message: error);
    } else {
      //   đúng otp
      setState(() => isLoading = false);
      CustomDialog.show(context: context, message: "Resend OTP success");
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text("Verify OTP", textAlign: TextAlign.center),
      content: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("OTP sent to ${widget.email}"),

              const SizedBox(height: 16),

              CustomTextField(
                label: "Enter OTP",
                controller: otpController,
              ),

              const SizedBox(height: 16),

              MyButton(
                label: "Confirm",
                onTap: isLoading ? null : _verifyOtp, // ❗ chặn spam
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: isLoading ? null : _resendOtp,
                child: const Text("Resend OTP"),
              ),
            ],
          ),

          // 🔥 LOADING OVERLAY TRONG DIALOG
          if (isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20), // match dialog
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}