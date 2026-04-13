import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button_group.dart';
import 'package:zalo_mobile_app/features/contact_screen/controllers/contact_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

import '../../conversation/controllers/conversation_controller.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final ContactController _contactController = ContactController(
    storage: const FlutterSecureStorage(),
  );
  final ConversationController _conversationController = ConversationController();

  final SocketService socketService = SocketService();

  StreamSubscription? _socketSubscription;

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _groupedFriends = [];

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _listenSocket();

  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final result = await _contactController.getFriends();

      if (!mounted) return;

      setState(() {
        _groupedFriends = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _listenSocket() {
    _socketSubscription?.cancel();

    _socketSubscription = socketService.eventsStream.listen((event) async {
      if (!mounted) return;

      final eventName = event["event"];
      final data = event["data"];

      debugPrint("📩 ContactScreen nhận socket event: $eventName");

      if (eventName == "notification:new") {
        try {
          final notification = Map<String, dynamic>.from(data as Map);

          final type = notification["type"]?.toString() ?? "";

          final rawData = notification["data"];
          final notiData = rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{};

          final status = notiData["status"]?.toString() ?? "";

          /// 👉 CASE: accept lời mời kết bạn
          if (type == "friend_request" && status == "accepted") {
            debugPrint("✅ Bạn mới được thêm → reload danh sách");

            await _fetchFriends();
          }
        } catch (e) {
          debugPrint("❌ Parse notification error: $e");
        }
      }
    });
  }
  Future<void> _openChat(Map<String, dynamic> friend) async {
    try {
      final conversations = await _conversationController.getListConversation();

      if (conversations == null) {
        throw Exception("Không lấy được danh sách conversation");
      }

      final friendUserId = (friend["userId"] ?? friend["_id"]).toString();
      Map<String, dynamic>? foundConversation;

      for (final item in conversations) {
        final conversation = Map<String, dynamic>.from(item);

        final members = List<Map<String, dynamic>>.from(
          (conversation["members"] ?? []).map((e) => Map<String, dynamic>.from(e)),
        );

        final hasFriend = members.any((member) {
          final userObj = member["userId"];
          if (userObj is Map<String, dynamic>) {
            return userObj["_id"]?.toString() == friendUserId;
          }
          if (userObj is Map) {
            return userObj["_id"]?.toString() == friendUserId;
          }
          return false;
        });

        if (hasFriend) {
          foundConversation = conversation;
          break;
        }
      }

      if (!mounted) return;

      if (foundConversation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy đoạn chat")),
        );
        return;
      }

      context.push(
        AppRoutes.chatScreen,
        extra: {
          "conversationId": foundConversation["_id"],
          "otherUserId": friendUserId,
          "name": friend["fullName"] ?? "",
          "avatar": friend["avatarUrl"] ?? "",
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi mở chat: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchFriends,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ListView(
              children: [
                _buildSearchBox(),
                const SizedBox(height: 12),
                MenuButtonGroup(
                  buttons: [
                    MenuButton(
                      icon: Icons.person_add,
                      label: "Liên hệ mới",
                      iconColor: Colors.blue,
                      onTap: () {
                        context.push(AppRoutes.addContactScreen);
                      },
                    ),
                    MenuButton(
                      icon: Icons.group_add,
                      label: "Nhóm mới",
                      iconColor: Colors.orange,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildContactList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Tìm kiếm",
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_groupedFriends.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text("Chưa có bạn bè nào"),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        itemCount: _groupedFriends.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final group = _groupedFriends[index];
          final letter = group["letter"] ?? "#";
          final friends = List<Map<String, dynamic>>.from(group["friends"] ?? []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF5F6F8),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...friends.map((friend) => _buildFriendItem(friend)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final fullName = friend["fullName"] ?? "";
    final avatarUrl = friend["avatarUrl"] ?? "";
    final isOnline = friend["isOnline"] ?? false;
    final firstChar = friend["firstChar"] ?? "#";
    print(friend);

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blue.shade100,
        backgroundImage:
        avatarUrl.toString().isNotEmpty ? NetworkImage(avatarUrl) : null,
        child: avatarUrl.toString().isEmpty
            ? Text(
          firstChar,
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        )
            : null,
      ),
      title: Text(
        fullName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        isOnline ? "Đang hoạt động" : "Không hoạt động",
        style: TextStyle(
          color: isOnline ? Colors.green : Colors.grey,
          fontSize: 12,
        ),
      ),
      onTap: () {
       _openChat(friend);
      },
    );
  }
}