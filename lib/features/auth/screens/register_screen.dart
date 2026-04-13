import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/popups/custom_dialog.dart';
import 'package:zalo_mobile_app/common/widgets/custom_text_field.dart';
import 'package:zalo_mobile_app/common/widgets/my_button.dart';
import 'package:zalo_mobile_app/features/auth/controllers/auth_controller.dart';
import 'package:zalo_mobile_app/features/auth/screens/confirm_register_dialog.dart';
import 'dart:convert';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final AuthController _authController = AuthController();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => isLoading = true);

    final error = await _authController.register(
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      phone: phoneController.text.trim(),
      confirmPassword: confirmPasswordController.text.trim(),
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (error != null) {
      CustomDialog.show(context: context, message: error);
    } else {
      showDialog(
          context: context,
          barrierDismissible: false, // KHông cho bấm ra ngoài
          builder: (context) => ConfirmRegisterDialog(email: emailController.text.trim())
      );
    }
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
                  const SizedBox(height: 40),

                  const Text(
                    "Register",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 40),

                  CustomTextField(label: "Fullname", controller: fullNameController),

                  const SizedBox(height: 16),

                  CustomTextField(label: "Email", controller: emailController),
                  const SizedBox(height: 16),

                  CustomTextField(label: "Phone", controller: phoneController),

                  const SizedBox(height: 16),

                  CustomTextField(label: "Password", controller: passwordController, isPasswordField: true),

                  const SizedBox(height: 16),

                  CustomTextField(label: "Confirm password", controller: confirmPasswordController, isPasswordField: true),

                  const SizedBox(height: 24),

                  MyButton(
                    label: "Register",
                    textColor: Colors.red,
                    onTap: isLoading ? null : _handleRegister, // ❗ chặn spam click
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Do you already have an account? "),
                      GestureDetector(
                        onTap: () {
                          context.go(AppRoutes.login);
                        },
                        child: const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),

          // 🔥 LOADING OVERLAY
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3), // nền mờ
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}