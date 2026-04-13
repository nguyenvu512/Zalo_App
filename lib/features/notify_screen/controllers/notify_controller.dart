import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class NotificationController {
  final FlutterSecureStorage storage;

  NotificationController({required this.storage});

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy token đăng nhập");
    }

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/notification?page=$page&limit=$limit",
    );

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception(decoded["message"] ?? "Lấy danh sách thông báo thất bại");
  }

  Future<void> acceptFriendRequest({
    required String friendshipId,
    required String notificationId,
    required String userId,
  }) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy token đăng nhập");
    }

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/friendship/accept",
    );

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "friendshipId": friendshipId,
      }),
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await markNotificationAsRead(
        notificationId: notificationId,
        userId: userId,
      );
      return;
    }

    throw Exception(decoded["message"] ?? "Chấp nhận lời mời thất bại");
  }
  Future<void> rejectFriendRequest({
    required String friendshipId,
    required String notificationId,
    required String userId,
  }) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy token đăng nhập");
    }

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/friendship/reject",
    );

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "friendshipId": friendshipId,
      }),
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await markNotificationAsRead(
        notificationId: notificationId,
        userId: userId,
      );
      return;
    }

    throw Exception(decoded["message"] ?? "Từ chối lời mời thất bại");
  }

  Future<void> markNotificationAsRead({
    required String notificationId,
    required String userId,
  }) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy token đăng nhập");
    }

    final url = Uri.parse(
      "${ApiConstants.baseUrl}/notification/$notificationId/read",
    );

    final response = await http.patch(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
      }),
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(decoded["message"] ?? "Đánh dấu đã đọc thất bại");
  }
}