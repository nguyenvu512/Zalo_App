import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Mới thêm
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zalo_mobile_app/common/constants/api_constants.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class AuthController {

  final storage = FlutterSecureStorage();

  Future<String?> handleLogin({
      required BuildContext context,
      required String email,
      required String password,
    }) async {
      // Validate
      if (email.isEmpty || password.isEmpty) {
        return "Please fill in all the information";
      }

      try {
        final url = Uri.parse("${ApiConstants.baseUrl}/auth/login");

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (data['code'] == 1000) {
            final accessToken = data['result']['accessToken'];
            Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
            final userId = decodedToken['userId'];
            // Conect socket
            SocketService().connect(userId);
            await storage.write(
              key: "access_token",
              value: accessToken,
            );
            await storage.write(
              key: "user_id",
              value: userId,
            );
            return null; // ✅ success
          } else {
            return "Login fail";
          }
        } else {
          return "Login fail ";
        }
      } catch (e) {
        print("Lỗi kết nối: $e");
        return "Lỗi kết nối: $e";
      }
  }

  Future<String?> verifyEmail({
    required String email,
    required String otp,
  }) async {
    // Validate
    if (email.isEmpty || otp.isEmpty) {
      return "Please fill in all the information";
    }

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/user/verify-email");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['message'] == "Verify success") {
          return null; // ✅ success
        } else {
          return "OTP incorrect";
        }
      } else {
        return "Server lỗi";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  Future<String?> resendOtp({
    required String email,
  }) async {
    // Validate
    if (email.isEmpty) {
      return "Please enter the email";
    }

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/user/resend-otp");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['message'] == "Resend OTP success") {
          return null; // ✅ success
        } else {
          return "Resend OTP fail";
        }
      } else {
        return "Server lỗi";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Validate
    if (fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      return "Please fill in all the information";
    }

    if (password != confirmPassword) {
      return "The confirm password does not match";
    }

    try {
      final url = Uri.parse("${ApiConstants.baseUrl}/user/register");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['message'] == "Register success") {
          return null; // ✅ success
        } else {
          return "Register fail";
        }
      } else {
        return "Register fail ";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

}