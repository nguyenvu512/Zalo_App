import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class CreateGroupInfoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedFriends;

  const CreateGroupInfoScreen({
    super.key,
    required this.selectedFriends,
  });

  @override
  State<CreateGroupInfoScreen> createState() => _CreateGroupInfoScreenState();
}

class _CreateGroupInfoScreenState extends State<CreateGroupInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ConversationController _conversationController = ConversationController();

  bool _isSubmitting = false;

  String _buildDefaultGroupName() {
    final names = widget.selectedFriends
        .map((e) => (e["fullName"] ?? "").toString())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();

    return names.join(", ");
  }

  Future<void> _createGroup() async {
    final groupName = _nameController.text.trim().isEmpty
        ? _buildDefaultGroupName()
        : _nameController.text.trim();

    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên nhóm")),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final memberIds = widget.selectedFriends
          .map((e) => (e["userId"] ?? e["_id"]).toString())
          .toList();

      final conversation = await _conversationController.createGroupConversation(
        name: groupName,
        memberIds: memberIds,
        avatarUrl: "",
      );

      if (!mounted) return;

      context.go(
        AppRoutes.chatScreen,
        extra: {
          "conversationId": conversation["_id"],
          "otherUserId": null,
          "name": conversation["name"] ?? groupName,
          "avatar": conversation["avatarUrl"] ?? "",
          "type":"group"
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Tạo nhóm thất bại: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildGroupAvatarPreview() {
    final firstChar = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : "G";

    return Column(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: Colors.orange.shade100,
          child: Text(
            firstChar,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Bạn có thể thêm chọn ảnh nhóm sau"),
              ),
            );
          },
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text("Chọn ảnh nhóm"),
        ),
      ],
    );
  }

  Widget _buildNameBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _nameController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Nhập tên nhóm",
          prefixIcon: Icon(Icons.group_outlined),
        ),
      ),
    );
  }

  Widget _buildMemberSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thành viên (${widget.selectedFriends.length})",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.selectedFriends.map((friend) {
            final fullName = (friend["fullName"] ?? "").toString();
            final avatarUrl = (friend["avatarUrl"] ?? "").toString();
            final firstChar =
            (friend["firstChar"] ?? (fullName.isNotEmpty ? fullName[0] : "#"))
                .toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                      firstChar,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = _buildDefaultGroupName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text("Thông tin nhóm"),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
                  : const Text(
                "Tạo nhóm",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildGroupAvatarPreview(),
            ),
            const SizedBox(height: 12),
            _buildNameBox(),
            const SizedBox(height: 12),
            _buildMemberSection(),
          ],
        ),
      ),
    );
  }
}