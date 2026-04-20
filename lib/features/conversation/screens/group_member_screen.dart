import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';

class GroupMembersScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;

  const GroupMembersScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
  });

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final ConversationController _conversationController =
  ConversationController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await _storage.read(key: 'user_id');
    await _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final members = await _conversationController.getGroupMembers(
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      setState(() {
        _members = members;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isCurrentUserOwner {
    if (_currentUserId == null) return false;

    return _members.any(
          (m) =>
      m['id']?.toString() == _currentUserId &&
          m['role']?.toString() == 'owner',
    );
  }

  bool _canManageMember(Map<String, dynamic> member) {
    final memberId = member['id']?.toString() ?? '';
    final memberRole = member['role']?.toString() ?? 'member';

    if (!_isCurrentUserOwner) return false;
    if (memberId.isEmpty) return false;
    if (memberId == _currentUserId) return false;
    if (memberRole == 'owner') return false;

    return true;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Trưởng nhóm';
      default:
        return 'Thành viên';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildAvatar(String avatarUrl, String fullName) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl),
      );
    }

    final firstChar = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.blue.shade100,
      child: Text(
        firstChar,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showMemberActions(Map<String, dynamic> member) {
    final fullName = member['fullName']?.toString() ?? 'Thành viên';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.person_remove_outlined,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Xóa khỏi nhóm',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmRemoveMember(member);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Bổ nhiệm trưởng nhóm'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmPromoteOwner(member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRemoveMember(Map<String, dynamic> member) {
    final fullName = member['fullName']?.toString() ?? 'Thành viên';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khỏi nhóm'),
        content: Text('Bạn có chắc muốn xóa $fullName khỏi nhóm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleRemoveMember(member);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPromoteOwner(Map<String, dynamic> member) {
    final fullName = member['fullName']?.toString() ?? 'Thành viên';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bổ nhiệm trưởng nhóm'),
        content: Text('Bạn có chắc muốn bổ nhiệm $fullName làm trưởng nhóm không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handlePromoteOwner(member);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRemoveMember(Map<String, dynamic> member) async {
    try {
      final memberId = member['id']?.toString() ?? '';
      if (memberId.isEmpty) return;

      setState(() {
        _isActionLoading = true;
      });

      await _conversationController.removeMemberFromGroup(
        conversationId: widget.conversationId,
        memberId: memberId,
      );

      if (!mounted) return;

      _showSnackBar('Xóa thành viên khỏi nhóm thành công');
      await _loadMembers();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _handlePromoteOwner(Map<String, dynamic> member) async {
    try {
      final memberId = member['id']?.toString() ?? '';
      if (memberId.isEmpty) return;

      setState(() {
        _isActionLoading = true;
      });

      await _conversationController.assignGroupOwner(
        conversationId: widget.conversationId,
        memberId: memberId,
      );

      if (!mounted) return;

      _showSnackBar('Bổ nhiệm trưởng nhóm thành công');
      await _loadMembers();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final fullName = member['fullName']?.toString() ?? '';
    final avatarUrl = member['avatarUrl']?.toString() ?? '';
    final role = member['role']?.toString() ?? 'member';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onLongPress: _canManageMember(member)
          ? () => _showMemberActions(member)
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(avatarUrl, fullName),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _roleColor(role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _roleLabel(role),
                style: TextStyle(
                  color: _roleColor(role),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMembers,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Text('Nhóm chưa có thành viên'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final member = _members[index];
        return _buildMemberItem(member);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Thành viên nhóm'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.08),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}