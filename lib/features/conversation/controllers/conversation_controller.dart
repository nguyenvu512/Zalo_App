import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class ConversationController {
  final storage = FlutterSecureStorage();

  Future<List<dynamic>?> getListConversation() async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse("${ApiConstants.baseUrl}/conversation/getByUserId");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // 🔥 QUAN TRỌNG
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 1000) {
        final List<dynamic> result = data['result'];

        result.sort((a, b) {
          final aTime =
              a["lastMessageId"]?["createdAt"] ?? a["createdAt"] ?? "";
          final bTime =
              b["lastMessageId"]?["createdAt"] ?? b["createdAt"] ?? "";
          return bTime.compareTo(aTime); // ← mới nhất lên đầu
        });

        return result;
      } else {
        throw Exception("Lấy conversation thất bại");
      }
    } catch (e) {
      throw Exception("Lỗi: $e");
    }
  }

  Future<Map<String, dynamic>> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String avatarUrl = "",
  }) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy access token");
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/conversation/group");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "name": name,
        "avatarUrl": avatarUrl,
        "memberIds": memberIds,
      }),
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(decoded["message"] ?? "Tạo nhóm thất bại");
    }

    final data = decoded["data"];
    if (data is! Map<String, dynamic>) {
      throw Exception("Dữ liệu nhóm trả về không hợp lệ");
    }

    return data;
  }

  Future<Map<String, dynamic>> searchMessages({
    required String conversationId,
    required String keyword,
    int page = 1,
    int limit = 20,
  }) async {
    final token = await storage.read(key: 'access_token');

    final uri =
        Uri.parse(
          '${ApiConstants.baseUrl}/message/$conversationId/search',
        ).replace(
          queryParameters: {
            'keyword': keyword,
            'page': '$page',
            'limit': '$limit',
          },
        );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getConversationMedia({
    required String conversationId,
    String type = 'all',
    int page = 1,
    int limit = 30,
  }) async {
    final token = await storage.read(key: 'access_token');

    final uri =
        Uri.parse(
          '${ApiConstants.baseUrl}/message/$conversationId/media',
        ).replace(
          queryParameters: {'type': type, 'page': '$page', 'limit': '$limit'},
        );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateGroupInfo({
    required String conversationId,
    String? name,
    File? avatarFile,
  }) async {
    final token = await storage.read(key: 'access_token');

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversation/group/$conversationId',
    );

    final request = http.MultipartRequest('PATCH', uri);

    request.headers['Authorization'] = 'Bearer $token';

    if (name != null && name.trim().isNotEmpty) {
      request.fields['name'] = name.trim();
    }

    if (avatarFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatarFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Cập nhật thông tin nhóm thất bại');
  }

  Future<Map<String, dynamic>> clearConversation({
    required String conversationId,
  }) async {
    try {
      final token = await storage.read(key: "access_token");

      if (token == null || token.isEmpty) {
        throw Exception("Không tìm thấy access token");
      }

      final url = Uri.parse(
        "${ApiConstants.baseUrl}/conversation/$conversationId/clear",
      );

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.body.trim().startsWith("<")) {
        throw Exception("Server trả về HTML thay vì JSON");
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      throw Exception(data["message"] ?? "Xóa cuộc trò chuyện thất bại");
    } catch (e) {
      throw Exception("Lỗi khi xóa cuộc trò chuyện: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getGroupMembers({
    required String conversationId,
  }) async {
    final token = await storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy access token');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversation/$conversationId/members',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception('Server trả về HTML thay vì JSON');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['code'] == 1000) {
      final result = data['result'];

      if (result is List) {
        return result
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }

      return [];
    }

    throw Exception(
      data['message'] ?? 'Lấy danh sách thành viên nhóm thất bại',
    );
  }

  Future<void> removeMemberFromGroup({
    required String conversationId,
    required String memberId,
  }) async {
    final token = await storage.read(key: 'access_token');

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversation/$conversationId/members/$memberId',
    );

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception('Server trả về HTML thay vì JSON');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['code'] == 1000) {
      return;
    }

    throw Exception(data['message'] ?? 'Xóa thành viên khỏi nhóm thất bại');
  }

  Future<void> assignGroupOwner({
    required String conversationId,
    required String memberId,
  }) async {
    final token = await storage.read(key: 'access_token');

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversation/$conversationId/owner',
    );

    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'memberId': memberId}),
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception('Server trả về HTML thay vì JSON');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['code'] == 1000) {
      return;
    }

    throw Exception(data['message'] ?? 'Bổ nhiệm trưởng nhóm thất bại');
  }

  Future<void> addMembersToGroup({
    required String conversationId,
    required List<String> userIds,
  }) async {
    final token = await storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Không tìm thấy access token');
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/conversation/$conversationId/members',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'memberIds': userIds}),
    );

    if (response.body.trim().startsWith('<')) {
      throw Exception('Server trả về HTML thay vì JSON');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['code'] == 1000) {
      return;
    }

    throw Exception(data['message'] ?? 'Thêm thành viên vào nhóm thất bại');
  }
  Future<Map<String, dynamic>> leaveGroup({
    required String conversationId,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Không tìm thấy access token');
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/conversation/$conversationId/leave',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.body.trim().startsWith('<')) {
        throw Exception('Server trả về HTML thay vì JSON');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['code'] == 1000) {
        return data;
      }

      throw Exception(data['message'] ?? 'Rời nhóm thất bại');
    } catch (e) {
      throw Exception('Lỗi khi rời nhóm: $e');
    }
  }
  Future<Map<String, dynamic>> dissolveGroup({
    required String conversationId,
  }) async {
    try {
      final token = await storage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw Exception('Không tìm thấy access token');
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/conversation/$conversationId/disband',
      );

      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.body.trim().startsWith('<')) {
        throw Exception('Server trả về HTML thay vì JSON');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data['code'] == 1000) {
        return data;
      }

      throw Exception(data['message'] ?? 'Giải tán nhóm thất bại');
    } catch (e) {
      throw Exception('Lỗi khi giải tán nhóm: $e');
    }
  }
}
