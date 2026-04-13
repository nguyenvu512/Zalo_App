import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class ProfileController {
  final FlutterSecureStorage storage;

  ProfileController({required this.storage});

  Future<Map<String, dynamic>> fetchUserInfo() async {
    final userId = await storage.read(key: "user_id");
    final token = await storage.read(key: "access_token");

    if (userId == null || token == null) {
      throw Exception("Thiếu thông tin đăng nhập");
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/user/$userId");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data['result']);
    }

    throw Exception(data['message'] ?? "Lấy thông tin thất bại");
  }


  Future<void> logout() async {
    try {
      final token = await storage.read(key: "access_token");
      final url = Uri.parse("${ApiConstants.baseUrl}/auth/logout");

      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      debugPrint("Logout API error: $e");
    }


    await storage.delete(key: "access_token");
    await storage.delete(key: "user_id");
  }
  Future<Map<String, dynamic>> updateUser({
    required String fullName,
    required String gender,
    required String bio,
    required String phone,
    required String? dateOfBirth,
  }) async {
    final userId = await storage.read(key: "user_id");
    final token = await storage.read(key: "access_token");

    if (userId == null || token == null) {
      throw Exception("Thiếu thông tin đăng nhập");
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/user/$userId");

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "fullName": fullName,
        "gender": gender,
        "bio": bio,
        "phone": phone,
        "dateOfBirth": dateOfBirth,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // 👉 gọi lại API để lấy data mới nhất
      return await fetchUserInfo();
    }

    throw Exception(data["message"] ?? "Cập nhật thất bại");
  }
  Future<dynamic> sendFriendRequest(String friendId) async {
    const storage = FlutterSecureStorage();

    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Chưa đăng nhập");
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/friendship/request");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "addresseeId": friendId,
      }),
    );
    return response.body;
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gửi lời mời thất bại");
    }
  }
}