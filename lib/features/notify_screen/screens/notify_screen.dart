import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/contact_screen/controllers/contact_controller.dart';
import 'package:zalo_mobile_app/features/notify_screen/controllers/notify_controller.dart';
import 'package:zalo_mobile_app/features/notify_screen/widgets/notify_card.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class NotifyScreen extends StatefulWidget {
  const NotifyScreen({super.key});

  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen> {
  final SocketService socketService = SocketService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  final List<Map<String, dynamic>> notifications = [];

  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  int unreadCount = 0;
  bool isLoading = true;
  String? userId;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    try {
      final savedUserId = await storage.read(key: "user_id");

      if (savedUserId == null || savedUserId.isEmpty) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
        return;
      }

      userId = savedUserId;

      await _loadNotifications();
      _listenSocket();
    } catch (e) {
      debugPrint("❌ NotifyScreen init error: $e");
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final controller = NotificationController(storage: storage);

      final result = await controller.getNotifications(
        page: 1,
        limit: 20,
      );

      final rawData = result["data"];

      if (rawData is! List) {
        throw Exception("data không phải list");
      }

      final loadedNotifications = rawData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((noti) {
        final isRead = noti["isRead"] == true;

        final data = noti["data"];
        String status = "";

        if (data is Map) {
          status = data["status"]?.toString() ?? "";
        }

        // ❌ Ẩn nếu pending + đã đọc
        return !(status == "pending" && isRead);
      })
          .toList();

      if (!mounted) return;

      setState(() {
        notifications
          ..clear()
          ..addAll(loadedNotifications);

        unreadCount = loadedNotifications
            .where((item) => item["isRead"] == false)
            .length;
      });
    } catch (e) {
      debugPrint("❌ Load notifications error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể tải thông báo: $e"),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _listenSocket() {
    _socketSubscription?.cancel();

    _socketSubscription = socketService.eventsStream.listen((event) {
      if (!mounted) return;

      final eventName = event["event"];
      final data = event["data"];

      debugPrint("📩 NotifyScreen nhận socket event: $eventName");

      if (eventName == "notification:new") {
        try {
          final newNotification = Map<String, dynamic>.from(data as Map);

          setState(() {
            notifications.insert(0, newNotification);

            final isRead = newNotification["isRead"] == true;
            if (!isRead) {
              unreadCount += 1;
            }
          });
        } catch (e) {
          debugPrint("❌ Parse notification:new error: $e");
        }
      }

      if (eventName == "notification:badge") {
        try {
          final badgeData = Map<String, dynamic>.from(data as Map);

          setState(() {
            unreadCount = badgeData["unreadCount"] ?? unreadCount;
          });
        } catch (e) {
          debugPrint("❌ Parse notification:badge error: $e");
        }
      }
    });
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _handleAccept(Map<String, dynamic> noti) async {
    try {
      final controller = NotificationController(storage: storage);

      final friendshipId = noti["data"]?["friendshipId"]?.toString() ?? "";
      final notificationId = noti["_id"]?.toString() ?? "";
      final userId = noti["userId"]?.toString() ?? "";

      if (friendshipId.isEmpty || notificationId.isEmpty || userId.isEmpty) {
        throw Exception("Thiếu dữ liệu để chấp nhận lời mời");
      }

      await controller.acceptFriendRequest(
        friendshipId: friendshipId,
        notificationId: notificationId,
        userId: userId,
      );
      await ContactController(storage:storage).getFriends();
      setState(() {
        notifications.removeWhere((item) => item["_id"] == notificationId);
        unreadCount = notifications.where((item) => item["isRead"] == false).length;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã chấp nhận lời mời kết bạn")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  Future<void> _handleReject(Map<String, dynamic> noti) async {
    try {
      final controller = NotificationController(storage: storage);

      final friendshipId = noti["data"]?["friendshipId"]?.toString() ?? "";
      final notificationId = noti["_id"]?.toString() ?? "";
      final userId = noti["userId"]?.toString() ?? "";

      if (friendshipId.isEmpty || notificationId.isEmpty || userId.isEmpty) {
        throw Exception("Thiếu dữ liệu để từ chối lời mời");
      }

      await controller.rejectFriendRequest(
        friendshipId: friendshipId,
        notificationId: notificationId,
        userId: userId,
      );

      setState(() {
        notifications.removeWhere((item) => item["_id"] == notificationId);
        unreadCount = notifications.where((item) => item["isRead"] == false).length;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã từ chối lời mời kết bạn")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  Widget _buildBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_none_rounded,
          color: Color(0xFF1E88E5),
          size: 28,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                unreadCount > 99 ? "99+" : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Thông báo",
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildBadge(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userId == null
          ? const Center(child: Text("Không tìm thấy user_id"))
          : RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: notifications.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 250),
            Center(
              child: Text(
                "Chưa có thông báo nào",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final noti = notifications[index];

            return NotificationCard(
              notification: noti,
              onTap: () {
                debugPrint("Tap notification: ${noti["_id"]}");
              },
              onAccept: (noti) async {
                await _handleAccept(noti);
              },
              onReject: (noti) async {
                await _handleReject(noti);
              },
            );
          },
        ),
      ),
    );
  }
}