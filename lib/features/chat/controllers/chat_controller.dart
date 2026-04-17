import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class ChatController {

  final storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required String type, // text | image | audio | sticker | file
    File? file,
    replyToMessageId,
    bool isForwarded = false,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    try {
      final token = await storage.read(key: "access_token");
      final url = Uri.parse("${ApiConstants.baseUrl}/message/send");

      final request = http.MultipartRequest("POST", url);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['conversationId'] = conversationId;
      request.fields['senderId'] = senderId;
      request.fields['content'] = content;
      request.fields['type'] = type; // 🔥 QUAN TRỌNG
      request.fields['isForwarded'] = isForwarded.toString();
      request.fields['replyToMessageId'] = replyToMessageId ?? "";
      if (attachments.isNotEmpty) {
        request.fields["attachments"] = jsonEncode(attachments);
      }

      // =========================
      // FILE UPLOAD
      // =========================
      if (file != null) {
        final mime = lookupMimeType(file.path)?.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'files',
            file.path,
            contentType: mime != null
                ? MediaType(mime[0], mime[1])
                : MediaType('application', 'octet-stream'),
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['code'] == 1000) {
        return data;
      } else {
        print("❌ Send error: ${response.body}");
        throw Exception("Send message failed");
      }
    } catch (e) {
      print("❌ Exception: $e");
      rethrow;
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

        // ✅ ÉP KIỂU CHUẨN
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        throw Exception("Load messages error");
      }
    } catch (e) {
      print("❌ Lỗi load message: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> revokeMessage(String messageId) async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse("${ApiConstants.baseUrl}/message/revoke");

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"messageId": messageId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 1000) {
        return Map<String, dynamic>.from(data['result']);
      } else {
        throw Exception("Revoke message error: ${data['message']}");
      }
    } catch (e) {
      print("❌ Lỗi thu hồi message: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse("${ApiConstants.baseUrl}/message/delete");

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"messageId": messageId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['code'] == 1000) {
        return Map<String, dynamic>.from(data['result']);
      } else {
        throw Exception("Revoke message error: ${data['message']}");
      }
    } catch (e) {
      print("❌ Lỗi thu hồi message: $e");
      rethrow;
    }
  }
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final token = await storage.read(key: "access_token");

      final url = Uri.parse("${ApiConstants.baseUrl}/message/chatbot");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "conversationId": conversationId,
          "content": content,
          if (replyToMessageId != null) "replyToMessageId": replyToMessageId,
        }),
      );

      // 🔥 check lỗi HTML (rất hay gặp)
      if (response.body.trim().startsWith("<")) {
        throw Exception("Server trả về HTML (có thể lỗi CORS / route)");
      }

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data["code"] == 1000) {
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception(data["message"] ?? "Chatbot error");
      }
    } catch (e) {
      print("❌ Chatbot Exception: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reactMessage({
    required String messageId,
    required String emoji,
  }) async {
    final token = await storage.read(key: "access_token");

    final res = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/message/reaction"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "messageId": messageId,
        "emoji": emoji,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200 && data["code"] == 1000) {
      return data;
    }

    throw Exception(data["message"] ?? "Thả cảm xúc thất bại");
  }


}