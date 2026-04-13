import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/popups/custom_dialog.dart';
import 'package:zalo_mobile_app/common/widgets/custom_text_field.dart';
import 'package:zalo_mobile_app/common/widgets/my_button.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import 'package:zalo_mobile_app/features/auth/controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthController _authController = AuthController();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool otpSent = false;

  Future<void> handleSendOtp() async {
    final email = emailController.text.trim();

    setState(() => isLoading = true);

    final message = await _authController.forgotPassword(email: email);

    if (!mounted) return;

    setState(() => isLoading = false);

    if (message == null) {
      CustomDialog.show(
        context: context,
        message: "Send OTP failed",
      );
      return;
    }

    setState(() => otpSent = true);

    CustomDialog.show(
      context: context,
      message: message,
    );
  }

  Future<void> handleVerifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();

    setState(() => isLoading = true);

    final message = await _authController.verifyForgotPasswordOtp(
      email: email,
      otp: otp,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (message == null) {
      CustomDialog.show(
        context: context,
        message: "OTP verification failed",
      );
      return;
    }

    CustomDialog.show(
      context: context,
      message: message,
    );

    context.go(AppRoutes.login);
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Forgot Password",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Enter your email to receive an OTP. After verifying OTP, a new password will be sent to your email.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(
                    label: "Email",
                    controller: emailController,
                  ),

                  const SizedBox(height: 16),

                  MyButton(
                    label: otpSent ? "Resend OTP" : "Send OTP",
                    onTap: handleSendOtp,
                  ),

                  if (otpSent) ...[
                    const SizedBox(height: 24),

                    CustomTextField(
                      label: "OTP",
                      controller: otpController,
                    ),

                    const SizedBox(height: 24),

                    MyButton(
                      label: "Verify OTP",
                      onTap: handleVerifyOtp,
                    ),
                  ],

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      context.go(AppRoutes.login);
                    },
                    child: const Text("Back to Login"),
                  ),
                ],
              ),
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}