import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:zalo_mobile_app/features/contact_screen/controllers/contact_controller.dart';
import 'package:zalo_mobile_app/routes/app_routes.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ContactController _contactController = ContactController(
    storage: const FlutterSecureStorage(),
  );

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _groupedFriends = [];
  List<Map<String, dynamic>> _filteredGroupedFriends = [];

  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFriends();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
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

  Future<void> _fetchFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final grouped = await _contactController.getFriends();

      if (!mounted) return;

      setState(() {
        _groupedFriends = List<Map<String, dynamic>>.from(
          grouped.map((e) => Map<String, dynamic>.from(e)),
        );
        _filteredGroupedFriends = List<Map<String, dynamic>>.from(
          grouped.map((e) => Map<String, dynamic>.from(e)),
        );
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

  void _handleSearch() {
    final keyword = _searchController.text.trim().toLowerCase();

    setState(() {
      if (keyword.isEmpty) {
        _filteredGroupedFriends = List<Map<String, dynamic>>.from(
          _groupedFriends.map((e) => Map<String, dynamic>.from(e)),
        );
        return;
      }

      final List<Map<String, dynamic>> filtered = [];

      for (final group in _groupedFriends) {
        final letter = (group["letter"] ?? "#").toString();
        final friends = List<Map<String, dynamic>>.from(group["friends"] ?? []);

        final matchedFriends = friends.where((friend) {
          final name = (friend["fullName"] ?? "").toString().toLowerCase();
          final phone = (friend["phone"] ?? "").toString().toLowerCase();
          return name.contains(keyword) || phone.contains(keyword);
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

  void _toggleSelect(Map<String, dynamic> friend) {
    final userId = (friend["userId"] ?? friend["_id"]).toString();

    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
    });
  }

  void _goNext() {
    if (_selectedIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ít nhất 2 người để tạo nhóm"),
        ),
      );
      return;
    }

    final selectedFriends = _allFriends.where((friend) {
      final id = (friend["userId"] ?? friend["_id"]).toString();
      return _selectedIds.contains(id);
    }).toList();

    context.push(
      AppRoutes.createGroupInfoScreen,
      extra: selectedFriends,
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

  Widget _buildSelectedPreview() {
    final selectedFriends = _allFriends.where((friend) {
      final id = (friend["userId"] ?? friend["_id"]).toString();
      return _selectedIds.contains(id);
    }).toList();

    if (selectedFriends.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: selectedFriends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final friend = selectedFriends[index];
          final fullName = (friend["fullName"] ?? "").toString();
          final avatarUrl = (friend["avatarUrl"] ?? "").toString();
          final firstChar =
          (friend["firstChar"] ?? (fullName.isNotEmpty ? fullName[0] : "#"))
              .toString();

          return Column(
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
                  Positioned(
                    top: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _toggleSelect(friend),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 58,
                child: Text(
                  fullName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFriendItem(Map<String, dynamic> friend) {
    final userId = (friend["userId"] ?? friend["_id"]).toString();
    final fullName = (friend["fullName"] ?? "").toString();
    final avatarUrl = (friend["avatarUrl"] ?? "").toString();
    final isOnline = friend["isOnline"] == true;
    final firstChar =
    (friend["firstChar"] ?? (fullName.isNotEmpty ? fullName[0] : "#"))
        .toString();

    final isSelected = _selectedIds.contains(userId);

    return InkWell(
      onTap: () => _toggleSelect(friend),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
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
      return const Expanded(
        child: Center(
          child: Text("Không tìm thấy bạn bè phù hợp"),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
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
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    return _buildGroupedFriendList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text("Nhóm mới"),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: selectedCount >= 2 ? _goNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                selectedCount >= 2
                    ? "Tiếp tục ($selectedCount)"
                    : "Chọn ít nhất 2 người",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildSearchBox(),
              _buildSelectedPreview(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }
}