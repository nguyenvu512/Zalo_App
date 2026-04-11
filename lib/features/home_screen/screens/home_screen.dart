import 'package:flutter/material.dart';
import 'package:zalo_mobile_app/features/message_screen/screens/message_screen.dart';
import 'package:zalo_mobile_app/features/profile_screen/screens/profile_screen.dart';
import 'dart:ui'; // 👈 quan trọng (blur)

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Center(child: MessageScreen()), // Thay bằng MessageScreen()
    const Center(child: Text('Contacts')),   // Thay bằng ContactScreen()
    const Center(child: Text('Discover')),  // Thay bằng DiscoverScreen()
    const Center(child: MessageScreen()),   // Thay bằng TimelineScreen()
    const Center(child: ProfileScreen()),   // Thay bằng ProfileScreen()
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 👈 cho phép thấy nền phía sau
      body: Stack(
        children: [
          /// Nội dung chính
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          /// Bottom menu dạng nổi
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // 👈 nền mờ
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildItem(Icons.chat_bubble_outline, 0),
                      _buildItem(Icons.contacts_outlined, 1),
                      _buildItem(Icons.explore_outlined, 2),
                      _buildItem(Icons.access_time_outlined, 3),
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