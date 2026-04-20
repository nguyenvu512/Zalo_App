import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';
import 'package:zalo_mobile_app/services/socket_service.dart';

class ConversationSettingScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String avatar;
  final String type;

  const ConversationSettingScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.avatar,
    required this.type,
  });

  @override
  State<ConversationSettingScreen> createState() =>
      _ConversationSettingScreenState();
}

class _ConversationSettingScreenState
    extends State<ConversationSettingScreen> {
  final ImagePicker _picker = ImagePicker();
  final ConversationController _conversationController =
  ConversationController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  late String _currentName;
  late String _currentAvatar;

  bool _isUpdating = false;
  bool _isDangerLoading = false;
  bool _isRoleLoading = false;
  bool _isOwner = false;

  bool get _isLoading => _isUpdating || _isDangerLoading || _isRoleLoading;

  @override
  void initState() {
    super.initState();
    _currentName = widget.name;
    _currentAvatar = widget.avatar;

    if (widget.type == 'group') {
      _loadMyGroupRole();
      _listenGroupDisbanded();
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  void _listenGroupDisbanded() {
    _socketSubscription?.cancel();
    _socketSubscription = SocketService().eventsStream.listen((event) {
      final eventName = event['event'];
      final data = event['data'];

      if (eventName != 'group_disbanded') return;
      if (data is! Map) return;
      if (!mounted) return;

      final payload = Map<String, dynamic>.from(data);
      final conversationId = payload['conversationId']?.toString() ?? '';

      if (conversationId != widget.conversationId) return;

      final message =
          payload['message']?.toString() ?? 'Nhóm đã bị giải tán';

      _showSnackBar(message);
      context.go(AppRoutes.home);
    });
  }

  Future<String?> _getCurrentUserId() async {
    final possibleKeys = [
      'userId',
      'user_id',
      'currentUserId',
      '_id',
      'id',
    ];

    for (final key in possibleKeys) {
      final value = await _storage.read(key: key);
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _normalizeMembers(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final result = response['result'];
      if (result is List) {
        return result
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return [];
  }

  Future<void> _loadMyGroupRole() async {
    try {
      setState(() => _isRoleLoading = true);

      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        return;
      }

      final response = await _conversationController.getGroupMembers(
        conversationId: widget.conversationId,
      );

      final members = _normalizeMembers(response);

      final me = members.cast<Map<String, dynamic>>().firstWhere(
            (member) {
          final memberId =
              member['id']?.toString() ?? member['_id']?.toString() ?? '';
          return memberId == currentUserId;
        },
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) return;

      setState(() {
        _isOwner = me['role']?.toString() == 'owner';
      });
    } catch (_) {
      // Không chặn UI nếu load role lỗi
    } finally {
      if (mounted) {
        setState(() => _isRoleLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleChangeGroupName() async {
    final controller = TextEditingController(text: _currentName);
    String tempName = _currentName;

    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final trimmed = tempName.trim();
            final canSave = trimmed.isNotEmpty && trimmed != _currentName;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                        const SizedBox(height: 18),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.drive_file_rename_outline_rounded,
                            color: Colors.blue.shade700,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Đổi tên nhóm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tên mới sẽ hiển thị với tất cả thành viên trong nhóm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: _currentAvatar.isNotEmpty
                                    ? NetworkImage(_currentAvatar)
                                    : null,
                                child: _currentAvatar.isEmpty
                                    ? const Icon(
                                  Icons.group,
                                  color: Colors.blue,
                                )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tên hiện tại',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 50,
                          onChanged: (value) {
                            setModalState(() {
                              tempName = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Nhập tên nhóm mới',
                            filled: true,
                            fillColor: const Color(0xFFF8F9FC),
                            prefixIcon: const Icon(Icons.edit_outlined),
                            suffixIcon: tempName.isNotEmpty
                                ? IconButton(
                              onPressed: () {
                                controller.clear();
                                setModalState(() {
                                  tempName = '';
                                });
                              },
                              icon: const Icon(Icons.close),
                            )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 1.4,
                              ),
                            ),
                            counterText: '${tempName.length}/50',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Hủy'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: canSave
                                    ? () => context.pop(trimmed)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Lưu'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (newName == null) return;
    if (newName.isEmpty) {
      _showSnackBar('Tên nhóm không được để trống');
      return;
    }
    if (newName == _currentName) return;

    try {
      setState(() => _isUpdating = true);

      final result = await _conversationController.updateGroupInfo(
        conversationId: widget.conversationId,
        name: newName,
      );

      final updatedName =
      result['result']?['name']?.toString().trim().isNotEmpty == true
          ? result['result']['name'].toString()
          : newName;

      if (!mounted) return;

      setState(() {
        _currentName = updatedName;
      });

      _showSnackBar('Đổi tên nhóm thành công');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleChangeGroupAvatar() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) {
        _showSnackBar('Bạn chưa chọn ảnh');
        return;
      }

      setState(() => _isUpdating = true);

      final result = await _conversationController.updateGroupInfo(
        conversationId: widget.conversationId,
        avatarFile: File(pickedFile.path),
      );

      final updatedAvatar =
          result['result']?['avatarUrl']?.toString() ?? _currentAvatar;

      if (!mounted) return;

      setState(() {
        _currentAvatar = updatedAvatar;
      });

      _showSnackBar('Đổi ảnh nhóm thành công');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleAddMembers() async {
    try {
      setState(() => _isUpdating = true);

      final response = await _conversationController.getGroupMembers(
        conversationId: widget.conversationId,
      );

      final members = _normalizeMembers(response);

      final excludeUserIds = members
          .map((e) => e['id']?.toString() ?? e['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (!mounted) return;

      setState(() => _isUpdating = false);

      final selectedUsers = await context.push<List<Map<String, dynamic>>>(
        AppRoutes.addGroupMembers,
        extra: {
          'conversationId': widget.conversationId,
          'groupName': _currentName,
          'excludeUserIds': excludeUserIds,
        },
      );

      if (!mounted || selectedUsers == null || selectedUsers.isEmpty) {
        return;
      }

      final userIds = selectedUsers
          .map((e) => e['id']?.toString() ?? e['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (userIds.isEmpty) {
        _showSnackBar('Không có thành viên hợp lệ để thêm');
        return;
      }

      setState(() => _isUpdating = true);

      await _conversationController.addMembersToGroup(
        conversationId: widget.conversationId,
        userIds: userIds,
      );

      if (!mounted) return;

      _showSnackBar('Thêm thành viên thành công');
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _handleClearConversation() async {
    try {
      setState(() => _isDangerLoading = true);

      await _conversationController.clearConversation(
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      _showSnackBar('Xóa cuộc trò chuyện thành công');
      context.go(AppRoutes.home);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isDangerLoading = false);
      }
    }
  }

  void _closeAfterRemovedConversation(String conversationId) {
    final result = {
      'removedConversationId': conversationId,
    };

    if (Navigator.of(context).canPop()) {
      context.pop(result);
    } else {
      context.go(AppRoutes.home);
    }
  }
  Future<void> _handleLeaveGroup() async {
    try {
      setState(() => _isDangerLoading = true);

      await _conversationController.leaveGroup(
        conversationId: widget.conversationId,
      );

      if (!mounted) return;

      _showSnackBar('Rời nhóm thành công');
      context.go(AppRoutes.home);
    } catch (e) {
      _showSnackBar(
        e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isDangerLoading = false);
      }
    }
  }

  Future<void> _handleDissolveGroup() async {
    try {
      setState(() => _isDangerLoading = true);

      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('Không xác định được user hiện tại');
      }

      await _conversationController.dissolveGroup(
        conversationId: widget.conversationId,
      );

      SocketService().emit('disband_group', {
        'conversationId': widget.conversationId,
        'userId': currentUserId,
        'groupName': _currentName,
      });

      if (!mounted) return;
      _closeAfterRemovedConversation(widget.conversationId);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isDangerLoading = false);
      }
    }
  }

  void _showClearConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện'),
        content: const Text(
          'Bạn có chắc muốn xóa cuộc trò chuyện này không?\n\n'
              'Hành động này chỉ xóa lịch sử cuộc trò chuyện của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: _isDangerLoading
                ? null
                : () async {
              Navigator.of(dialogContext).pop();
              await _handleClearConversation();
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

  void _showLeaveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rời nhóm'),
        content: const Text(
          'Bạn có chắc muốn rời khỏi nhóm này không?\n\n'
              'Sau khi rời nhóm, bạn sẽ không còn nhận được tin nhắn mới từ nhóm nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: _isDangerLoading
                ? null
                : () async {
              Navigator.of(dialogContext).pop();
              await _handleLeaveGroup();
            },
            child: const Text(
              'Rời nhóm',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDissolveGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Giải tán nhóm'),
        content: const Text(
          'Bạn có chắc muốn giải tán nhóm này không?\n\n'
              'Hành động này sẽ xóa nhóm cho tất cả thành viên và không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: _isDangerLoading
                ? null
                : () async {
              Navigator.of(dialogContext).pop();
              await _handleDissolveGroup();
            },
            child: const Text(
              'Giải tán',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage:
            _currentAvatar.isNotEmpty ? NetworkImage(_currentAvatar) : null,
            child: _currentAvatar.isEmpty
                ? Icon(
              widget.type == 'group' ? Icons.group : Icons.person,
              size: 40,
            )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _currentName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            widget.type == 'group' ? 'Nhóm chat' : 'Trò chuyện cá nhân',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.type == 'group';
    final isBot = widget.type == 'bot';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Thông tin cuộc trò chuyện'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () =>
              context.pop({'name': _currentName, 'avatar': _currentAvatar}),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSection(
                children: [
                  _buildTile(
                    icon: Icons.search,
                    title: 'Tìm tin nhắn',
                    onTap: () async {
                      final targetMessageId = await context.push<String>(
                        AppRoutes.searchMessage,
                        extra: {
                          'conversationId': widget.conversationId,
                          'name': _currentName,
                          'avatar': _currentAvatar,
                        },
                      );

                      if (!mounted ||
                          targetMessageId == null ||
                          targetMessageId.isEmpty) {
                        return;
                      }

                      context.pop({
                        'name': _currentName,
                        'avatar': _currentAvatar,
                        'targetMessageId': targetMessageId,
                      });
                    },
                  ),
                  _buildDivider(),
                  _buildTile(
                    icon: Icons.image,
                    title: 'Ảnh, video, file',
                    onTap: () {
                      context.push(
                        AppRoutes.conversationMedia,
                        extra: {
                          'conversationId': widget.conversationId,
                          'name': _currentName,
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isGroup)
                _buildSection(
                  children: [
                    _buildTile(
                      icon: Icons.palette_outlined,
                      title: 'Đổi ảnh nhóm',
                      onTap: _isUpdating ? () {} : _handleChangeGroupAvatar,
                    ),
                    _buildDivider(),
                    _buildTile(
                      icon: Icons.drive_file_rename_outline,
                      title: 'Đổi tên nhóm',
                      onTap: _isUpdating ? () {} : _handleChangeGroupName,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (isGroup)
                _buildSection(
                  children: [
                    _buildTile(
                      icon: Icons.group_outlined,
                      title: 'Xem thành viên nhóm',
                      onTap: () {
                        context.push(
                          AppRoutes.groupMembers,
                          extra: {
                            'conversationId': widget.conversationId,
                            'groupName': _currentName,
                          },
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildTile(
                      icon: Icons.person_add_alt_1,
                      title: 'Thêm thành viên',
                      onTap: _isUpdating ? () {} : _handleAddMembers,
                    ),
                  ],
                ),
              if (isGroup) const SizedBox(height: 16),
              if (!isBot)
                _buildSection(
                  children: [
                    _buildTile(
                      icon: Icons.delete,
                      title: 'Xóa cuộc trò chuyện',
                      textColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        _showClearConversationDialog(context);
                      },
                    ),
                  ],
                ),
              if (isGroup) const SizedBox(height: 16),
              if (isGroup)
                _buildSection(
                  children: [
                    if (_isOwner)
                      _buildTile(
                        icon: Icons.delete_forever,
                        title: 'Giải tán nhóm',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () {
                          _showDissolveGroupDialog(context);
                        },
                      )
                    else
                      _buildTile(
                        icon: Icons.logout,
                        title: 'Rời nhóm',
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () {
                          _showLeaveGroupDialog(context);
                        },
                      ),
                  ],
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.08),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}