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
          final aTime = a["lastMessageId"]?["createdAt"] ?? a["createdAt"] ?? "";
          final bTime = b["lastMessageId"]?["createdAt"] ?? b["createdAt"] ?? "";
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

}