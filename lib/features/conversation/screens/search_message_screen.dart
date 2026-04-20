import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';

class SearchMessageScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String avatar;

  const SearchMessageScreen({
    super.key,
    required this.conversationId,
    required this.name,
    required this.avatar
  });

  @override
  State<SearchMessageScreen> createState() => _SearchMessageScreenState();
}

class _SearchMessageScreenState extends State<SearchMessageScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ConversationController _conversationController =
  ConversationController();

  bool _isLoading = false;
  String _keyword = '';
  String? _errorMessage;
  List<Map<String, dynamic>> _messages = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchMessages() async {
    final keyword = _searchController.text.trim();

    setState(() {
      _keyword = keyword;
      _errorMessage = null;
    });

    if (keyword.isEmpty) {
      setState(() {
        _messages = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _conversationController.searchMessages(
        conversationId: widget.conversationId,
        keyword: keyword,
        page: 1,
        limit: 20,
      );

      final rawList = response['data']?['data'];

      if (rawList is List) {
        final mapped = rawList.map<Map<String, dynamic>>((item) {
          final sender = item['senderId'];
          final attachments = item['attachments'];

          String content = item['content']?.toString().trim() ?? '';
          final type = item['type']?.toString() ?? 'text';

          if (content.isEmpty) {
            if (attachments is List && attachments.isNotEmpty) {
              final firstAttachment = attachments.first;
              final fileName =
              firstAttachment is Map ? firstAttachment['fileName'] : null;

              if (fileName != null && fileName.toString().trim().isNotEmpty) {
                content = fileName.toString();
              } else {
                content = _buildTypeLabel(type);
              }
            } else {
              content = _buildTypeLabel(type);
            }
          }

          return {
            '_id': item['_id']?.toString() ?? '',
            'senderName': sender is Map
                ? (sender['fullName']?.toString() ?? 'Người dùng')
                : 'Người dùng',
            'avatarUrl': sender is Map
                ? (sender['avatarUrl']?.toString() ?? '')
                : '',
            'content': content,
            'createdAt': item['createdAt']?.toString() ?? '',
            'type': type,
            'isForwarded': item['isForwarded'] == true,
            'isRecalled': item['isRecalled'] == true,
            'replyToMessageId': item['replyToMessageId'],
          };
        }).toList();

        if (!mounted) return;
        setState(() {
          _messages = mapped;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _messages = [];
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = [];
        _errorMessage = 'Tìm kiếm thất bại: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildTypeLabel(String type) {
    switch (type) {
      case 'image':
        return '[Hình ảnh]';
      case 'video':
        return '[Video]';
      case 'audio':
        return '[Âm thanh]';
      case 'file':
        return '[Tệp đính kèm]';
      case 'sticker':
        return '[Sticker]';
      case 'system':
        return '[Tin nhắn hệ thống]';
      case 'mixed':
        return '[Tin nhắn kèm tệp]';
      default:
        return '[Tin nhắn]';
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';

    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }

  List<TextSpan> _buildHighlightedText(String text, String keyword) {
    if (keyword.trim().isEmpty) {
      return [
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ];
    }
    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = lowerText.indexOf(lowerKeyword);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.45,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
            height: 1.45,
            backgroundColor: Colors.blue.shade50,
          ),
        ),
      );

      start = index + keyword.length;
      index = lowerText.indexOf(lowerKeyword, start);
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.45,
          ),
        ),
      );
    }

    return spans;
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey.shade200,
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blue.shade100,
      child: const Icon(Icons.person, color: Colors.blue),
    );
  }

  Widget _buildTypeChip(String type) {
    if (type == 'text') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _buildTypeLabel(type),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildReplyPreview(dynamic replyData) {
    if (replyData == null || replyData is! Map) {
      return const SizedBox.shrink();
    }

    final sender = replyData['senderId'];
    final senderName =
    sender is Map ? (sender['fullName']?.toString() ?? 'Người dùng') : 'Người dùng';
    final content = replyData['content']?.toString().trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: Colors.blue.shade300,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trả lời $senderName',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content.isNotEmpty ? content : '[Tin nhắn được trả lời]',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_keyword.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Nhập từ khóa để tìm tin nhắn',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _searchMessages,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'Không tìm thấy tin nhắn phù hợp',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _messages[index];
        final avatarUrl = item['avatarUrl']?.toString() ?? '';
        final senderName = item['senderName']?.toString() ?? '';
        final content = item['content']?.toString() ?? '';
        final createdAt = item['createdAt']?.toString() ?? '';
        final type = item['type']?.toString() ?? 'text';
        final replyToMessageId = item['replyToMessageId'];
        final isForwarded = item['isForwarded'] == true;

        return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(avatarUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateTime(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (isForwarded)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Đã chuyển tiếp',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _buildReplyPreview(replyToMessageId),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        children: _buildHighlightedText(content, _keyword),
                      ),
                    ),
                    _buildTypeChip(type),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          final messageId = item['_id']?.toString() ?? '';
                          if (messageId.isEmpty) return;

                          Navigator.pop(context, messageId);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Đi tới tin nhắn'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _keyword = '';
      _messages = [];
      _errorMessage = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Tìm trong ${widget.name}'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchMessages(),
                      onChanged: (_) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập nội dung cần tìm...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchMessages,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(72, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Tìm'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }
}