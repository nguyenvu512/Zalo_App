import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button_group.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12), // ✅ padding toàn page
          child: ListView(
            children: [
              /// 🔍 Search box
              _buildSearchBox(),

              const SizedBox(height: 12),

              /// 🔹 Group - Contact actions
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

              /// 📋 Contact list
              _buildContactList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔍 Search UI
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

  /// 📌 Demo list contact
  Widget _buildContactList() {
    final contacts = [
      "Nguyễn Văn A",
      "Trần Thị B",
      "Lê Văn C",
      "Phạm Văn D",
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        itemCount: contacts.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                contacts[index][0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(contacts[index]),
            onTap: () {},
          );
        },
      ),
    );
  }
}