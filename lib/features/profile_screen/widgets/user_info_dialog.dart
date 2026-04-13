import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserInfoDialog extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Future<void> Function({
  required String fullName,
  required String gender,
  required String bio,
  required String phone,
  required String? dateOfBirth,
  }) onSave;

  const UserInfoDialog({
    super.key,
    required this.userData,
    required this.onSave,
  });

  @override
  State<UserInfoDialog> createState() => _UserInfoDialogState();
}

class _UserInfoDialogState extends State<UserInfoDialog> {
  late final TextEditingController fullNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;
  late final TextEditingController bioController;
  late final TextEditingController dateOfBirthController;

  late String gender;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    fullNameController = TextEditingController(
      text: widget.userData?['fullName']?.toString() ?? '',
    );

    emailController = TextEditingController(
      text: widget.userData?['email']?.toString() ?? '',
    );
    phoneController = TextEditingController(
      text: widget.userData?['phone']?.toString()??'',
    );

    bioController = TextEditingController(
      text: widget.userData?['bio']?.toString() ?? '',
    );

    final rawDob = widget.userData?['dateOfBirth']?.toString();
    dateOfBirthController = TextEditingController(
      text: _formatDateForInput(rawDob),
    );

    gender = _normalizeGender(widget.userData?['gender']?.toString());
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    bioController.dispose();
    phoneController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  String _normalizeGender(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      default:
        return 'other';
    }
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Nam';
      case 'female':
        return 'Nữ';
      default:
        return 'Khác';
    }
  }

  String _formatDateForInput(String? isoString) {
    if (isoString == null || isoString.isEmpty || isoString == "null") {
      return '';
    }

    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatDateDisplay(String? isoString) {
    if (isoString == null || isoString.isEmpty || isoString == "null") {
      return "Chưa cập nhật";
    }

    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return "Chưa cập nhật";
    }
  }

  String? _convertInputDateToIso(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final date = DateFormat('dd/MM/yyyy').parseStrict(value.trim());
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      throw Exception("Ngày sinh không đúng định dạng dd/MM/yyyy");
    }
  }

  ImageProvider _buildAvatarProvider() {
    final avatarUrl = widget.userData?['avatarUrl'];
    final fullName = widget.userData?['fullName'] ?? 'User';

    if (avatarUrl != null && avatarUrl.toString().trim().isNotEmpty) {
      return NetworkImage(avatarUrl);
    }

    return NetworkImage(
      "https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(fullName.toString())}",
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initialDate = DateTime(now.year - 18, 1, 1);

    final rawDob = widget.userData?['dateOfBirth']?.toString();
    if (rawDob != null && rawDob.isNotEmpty && rawDob != "null") {
      try {
        initialDate = DateTime.parse(rawDob).toLocal();
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked != null) {
      dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _handleSave() async {
    final fullName = fullNameController.text.trim();
    final bio = bioController.text.trim();

    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Họ và tên không được để trống")),
      );
      return;
    }

    try {
      setState(() => isSaving = true);

      final dobIso = _convertInputDateToIso(dateOfBirthController.text);

      await widget.onSave(
        fullName: fullName,
        gender: gender,
        bio: bio,
        phone: phoneController.text.trim(),
        dateOfBirth: dobIso,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly || onTap != null,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: onTap != null ? const Icon(Icons.calendar_month) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF3F7FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTile({
    required String title,
    required bool value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = widget.userData?['isOnline'] == true;
    final isVerified = widget.userData?['isVerified'] == true;

    final settings =
        (widget.userData?['settings'] as Map<String, dynamic>?) ?? {};

    final allowStrangerMessage =
        settings['allowStrangerMessage'] == true;
    final showPhone = settings['showPhone'] == true;
    final showLastSeen = settings['showLastSeen'] == true;

    final status = widget.userData?['status']?.toString() ?? 'unknown';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),

              CircleAvatar(
                radius: 42,
                backgroundImage: _buildAvatarProvider(),
              ),
              const SizedBox(height: 12),

              Text(
                widget.userData?['fullName']?.toString() ?? "Người dùng",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(
                    label: isOnline ? "Đang online" : "Đang offline",
                    color: isOnline ? Colors.green : Colors.grey,
                    icon: Icons.circle,
                  ),
                  _buildStatusChip(
                    label: isVerified ? "Đã xác thực" : "Chưa xác thực",
                    color: isVerified ? Colors.blue : Colors.orange,
                    icon: isVerified ? Icons.verified : Icons.error_outline,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSectionTitle("Thông tin cơ bản"),
              _buildTextField(
                controller: fullNameController,
                label: "Họ và tên",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: emailController,
                label: "Email",
                icon: Icons.email_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: phoneController,
                label: "Số điện thoại",
                icon: Icons.phone_callback_outlined,
                readOnly: false,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: gender,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => gender = value);
                  }
                },
                decoration: InputDecoration(
                  labelText: "Giới tính",
                  prefixIcon: const Icon(Icons.wc_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF3F7FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
              ),

              const SizedBox(height: 12),
              _buildTextField(
                controller: dateOfBirthController,
                label: "Ngày sinh",
                icon: Icons.cake_outlined,
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: bioController,
                label: "Tiểu sử",
                icon: Icons.info_outline,
                maxLines: 3,
              ),

              const SizedBox(height: 22),

              _buildSectionTitle("Thông tin hệ thống"),
              _buildInfoCard(
                icon: Icons.history,
                title: "Lần hoạt động cuối",
                value: _formatDateDisplay(
                  widget.userData?['lastSeenAt']?.toString(),
                ),
              ),
              _buildInfoCard(
                icon: Icons.event_available,
                title: "Ngày tạo tài khoản",
                value: _formatDateDisplay(
                  widget.userData?['createdAt']?.toString(),
                ),
              ),
              _buildInfoCard(
                icon: Icons.update,
                title: "Cập nhật gần nhất",
                value: _formatDateDisplay(
                  widget.userData?['updatedAt']?.toString(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text("Đóng"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        "Lưu thay đổi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}