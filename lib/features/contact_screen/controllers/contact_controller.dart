import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class ContactController {
  final FlutterSecureStorage storage;

  ContactController({required this.storage});

  Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final token = await storage.read(key: "access_token");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy token đăng nhập");
    }

    final url = Uri.parse("${ApiConstants.baseUrl}/user/search/?phone=$phone");

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

    if (response.statusCode == 200 && decoded["data"] != null) {
      return decoded["data"];
    }

    return null;
  }
  Future<List<Map<String, dynamic>>> getFriends({List<String>? excludeUserIds}) async {
    final token = await storage.read(key: "access_token");
    final userId = await storage.read(key: "user_id");

    if (token == null || token.isEmpty) {
      throw Exception("Không tìm thấy access token");
    }

    if (userId == null || userId.isEmpty) {
      throw Exception("Không tìm thấy userId");
    }

    final uri = Uri.parse("${ApiConstants.baseUrl}/friendship/friends").replace(
      queryParameters: {
        if (excludeUserIds != null && excludeUserIds.isNotEmpty)
          "excludeUserIds": excludeUserIds.join(","),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.body.trim().startsWith("<")) {
      throw Exception("Server trả về HTML thay vì JSON");
    }

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded is Map<String, dynamic>
            ? (decoded["message"] ?? "Lấy danh sách bạn bè thất bại")
            : "Lấy danh sách bạn bè thất bại",
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Response không hợp lệ");
    }

    final data = decoded["data"];

    if (data is! Map<String, dynamic>) {
      throw Exception("Dữ liệu bạn bè không hợp lệ");
    }

    final result = <Map<String, dynamic>>[];
    final sortedKeys = data.keys.toList()..sort();

    for (final key in sortedKeys) {
      final friendsRaw = data[key];

      if (friendsRaw is! List) continue;

      result.add({
        "letter": key,
        "friends": List<Map<String, dynamic>>.from(friendsRaw),
      });
    }

    return result;
  }

}