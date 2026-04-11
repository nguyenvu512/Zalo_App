import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class ChatController {

  final storage = FlutterSecureStorage();

  Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse("${ApiConstants.baseUrl}/message/send");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'conversationId': conversationId,
          'content': content,
          'senderId': senderId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['code'] == 1000) {
        return true;
      } else {
        print("❌ Server logic error: ${response.body}");
        throw Exception("Send message error");
      }
    } catch (e) {
      print("Lỗi: $e");
      throw Exception("Lỗi: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse(
        "${ApiConstants.baseUrl}/message/conversation/$conversationId",
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 1000) {
        final List list = data['result']['data'];

        return list.map((item) {
          return {
            "message": item["content"],
            "userId": item["senderId"]["_id"],
            "createdAt": item["createdAt"],
          };
        }).toList();
      } else {
        throw Exception("Load messages error");
      }
    } catch (e) {
      print("❌ Lỗi load message: $e");
      rethrow;
    }
  }

}