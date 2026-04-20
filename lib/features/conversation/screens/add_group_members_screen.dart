import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/contact_screen/controllers/contact_controller.dart';

class AddGroupMembersScreen extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final List<String> excludeUserIds;

  const AddGroupMembersScreen({
    super.key,
    required this.conversationId,
    required this.groupName,
    required this.excludeUserIds,
  });

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final ContactController _friendshipController = ContactController(
    storage: const FlutterSecureStorage(),
  );

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _groupedFriends = [];
  List<Map<String, dynamic>> _filteredGroupedFriends = [];

  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _allFriends {
    final List<Map<String, dynamic>> result = [];

    for (final group in _groupedFriends) {
      final friends = List<Map<String, dynamic>>.from(group["friends"] ?? []);
      result.addAll(friends);
    }

    return result;
  }

  Future<void> _loadFriends() async {
    try {
      setState(() => _isLoading = true);

      final response = await _friendshipController.getFriends(
        excludeUserIds: widget.excludeUserIds,
      );

      final List<Map<String, dynamic>> grouped = [];

      if (response is List) {
        for (final group in response) {
          if (group is Map<String, dynamic>) {
            grouped.add({
              "letter": (group["letter"] ?? "#").toString(),
              "friends": List<Map<String, dynamic>>.from(group["friends"] ?? []),
            });
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _groupedFriends = grouped;
        _filteredGroupedFriends = grouped
            .map((e) => {
          "letter": e["letter"],
          "friends": List<Map<String, dynamic>>.from(e["friends"] ?? []),
        })
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSearch() {
    final keyword = _searchController.text.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        _filteredGroupedFriends = _groupedFriends
            .map((e) => {
          "letter": e["letter"],
          "friends": List<Map<String, dynamic>>.from(e["friends"] ?? []),
        })
            .toList();
        return;
      }

      final List<Map<String, dynamic>> filtered = [];

      for (final group in _groupedFriends) {
        final letter = (group["letter"] ?? "#").toString();
        final friends = List<Map<String, dynamic>>.from(group["friends"] ?? []);

        final matchedFriends = friends.where((friend) {
          final fullName = (friend['fullName'] ?? '').toString().toLowerCase();
          final fullNameNormalized =
          (friend['fullNameNormalized'] ?? '').toString().toLowerCase();
          final phone = (friend['phone'] ?? '').toString().toLowerCase();

          return fullName.contains(keyword) ||
              fullNameNormalized.contains(keyword) ||
              phone.contains(keyword);
        }).toList();

        if (matchedFriends.isNotEmpty) {
          filtered.add({
            "letter": letter,
            "friends": matchedFriends,
          });
        }
      }

      _filteredGroupedFriends = filtered;
    });
  }

  void _toggleUser(String userId) {
    if (userId.isEmpty) return;

    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  void _submitSelectedUsers() {
    final selectedUsers = _allFriends.where((friend) {
      final id = (friend['_id'] ?? friend['id'] ?? '').toString();
      return _selectedUserIds.contains(id);
    }).toList();

    context.pop<List<Map<String, dynamic>>>(selectedUsers);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Tìm bạn bè",
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: const Icon(Icons.close, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedCount() {
    if (_selectedUserIds.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Đã chọn ${_selectedUserIds.length} thành viên',
          style: TextStyle(
            fontSize: 13,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final userId = (friend['_id'] ?? friend['id'] ?? '').toString();
    final fullName = (friend['fullName'] ?? 'Không tên').toString();
    final avatarUrl = (friend['avatarUrl'] ?? '').toString();
    final isOnline = friend['isOnline'] == true;
    final isSelected = _selectedUserIds.contains(userId);
    final firstChar =
    (friend["firstChar"] ?? (fullName.isNotEmpty ? fullName[0] : "#"))
        .toString();

    return InkWell(
      onTap: () => _toggleUser(userId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
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
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline ? "Đang hoạt động" : "Không hoạt động",
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedFriendList() {
    if (_filteredGroupedFriends.isEmpty) {
      return const Center(
        child: Text(
          'Không có bạn bè nào để thêm',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.builder(
        itemCount: _filteredGroupedFriends.length,
        itemBuilder: (context, index) {
          final group = _filteredGroupedFriends[index];
          final letter = (group["letter"] ?? "#").toString();
          final friends =
          List<Map<String, dynamic>>.from(group["friends"] ?? []);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF5F6F8),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...friends.asMap().entries.map((entry) {
                final friendIndex = entry.key;
                final friend = entry.value;

                return Column(
                  children: [
                    _buildFriendItem(friend),
                    if (friendIndex != friends.length - 1)
                      Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                        indent: 74,
                      ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildGroupedFriendList();
  }

  Widget _buildBottomButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _selectedUserIds.isEmpty || _isSubmitting
                ? null
                : _submitSelectedUsers,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _selectedUserIds.isEmpty
                  ? 'Chọn thành viên'
                  : 'Thêm ${_selectedUserIds.length} thành viên',
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Thêm vào ${widget.groupName}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                _buildSearchBox(),
                _buildSelectedCount(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildBody(),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }
}