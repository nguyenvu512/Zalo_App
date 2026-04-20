import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/contact_screen/screens/contact_screen.dart';
import 'package:zalo_mobile_app/features/message_screen/screens/message_screen.dart';
import 'package:zalo_mobile_app/features/notify_screen/screens/notify_screen.dart';
import 'package:zalo_mobile_app/features/profile_screen/screens/profile_screen.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final List<Widget> _screens = const [
    MessageScreen(),
    ContactScreen(),
    Center(child: Text('Discover')),
    NotifyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  Future<void> _initSocket() async {
    final userId = await _storage.read(key: "user_id");

    if (userId != null && userId.isNotEmpty) {
      SocketService().connect(userId);

      // đăng ký các event global ở đây nếu muốn
      SocketService().listenEvent("receive_message");
      SocketService().listenEvent("message_recalled");
      SocketService().listenEvent("message_deleted");
      SocketService().listenEvent("notification:new");
      SocketService().listenEvent("notification:badge");
      SocketService().listenEvent('group_disbanded');
      SocketService().listenEvent("added_to_group");
      SocketService().listenEvent("removed_from_group");
      print("✅ Socket initialized in HomeScreen with userId: $userId");
    } else {
      print("❌ Không tìm thấy user_id để connect socket");
    }
  }

  Widget _buildItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Icon(
        icon,
        color: isSelected ? Colors.blueAccent : Colors.black38,
        size: 24,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    // Nếu HomeScreen là root sau login và bạn muốn socket sống toàn app
    // thì có thể KHÔNG disconnect ở đây.
    // SocketService().disconnect();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildItem(Icons.chat_bubble_outline, 0),
                      _buildItem(Icons.contacts_outlined, 1),
                      _buildItem(Icons.explore_outlined, 2),
                      _buildItem(Icons.notifications, 3),
                      _buildItem(Icons.person_outline, 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}