import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:zalo_mobile_app/common/constants/api_constants.dart';
import 'package:zalo_mobile_app/features/conversation/controllers/conversation_controller.dart';

class ConversationMediaScreen extends StatefulWidget {
  final String conversationId;
  final String name;

  const ConversationMediaScreen({
    super.key,
    required this.conversationId,
    required this.name,
  });

  @override
  State<ConversationMediaScreen> createState() => _ConversationMediaScreenState();
}

class _ConversationMediaScreenState extends State<ConversationMediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final ConversationController _controller = ConversationController();

  final ScrollController _imageScrollController = ScrollController();
  final ScrollController _videoScrollController = ScrollController();
  final ScrollController _fileScrollController = ScrollController();

  final int _limit = 30;

  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _files = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  int _page = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _imageScrollController.addListener(() => _handleScroll(_imageScrollController));
    _videoScrollController.addListener(() => _handleScroll(_videoScrollController));
    _fileScrollController.addListener(() => _handleScroll(_fileScrollController));

    _fetchMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imageScrollController.dispose();
    _videoScrollController.dispose();
    _fileScrollController.dispose();
    super.dispose();
  }

  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients || _isLoading || _isLoadingMore || !_hasMore) return;

    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchMedia({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || !_hasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
        _totalPages = 1;
        _hasMore = true;
        _images = [];
        _videos = [];
        _files = [];
      });
    }

    try {
      final res = await _controller.getConversationMedia(
        conversationId: widget.conversationId,
        type: 'all',
        page: _page,
        limit: _limit,
      );

      final List<dynamic> items =
      (res['data']?['data'] as List<dynamic>? ?? <dynamic>[]);

      final Map<String, dynamic> pagination =
      (res['data']?['pagination'] as Map<String, dynamic>? ?? <String, dynamic>{});

      final newImages = <Map<String, dynamic>>[];
      final newVideos = <Map<String, dynamic>>[];
      final newFiles = <Map<String, dynamic>>[];

      for (final rawItem in items) {
        if (rawItem is! Map<String, dynamic>) continue;

        final attachment = rawItem['attachment'];
        if (attachment is! Map<String, dynamic>) continue;

        final type = (attachment['type'] ?? '').toString().toLowerCase();

        final mediaItem = {
          'message': rawItem,
          'attachment': attachment,
        };

        if (type == 'image') {
          newImages.add(mediaItem);
        } else if (type == 'video') {
          newVideos.add(mediaItem);
        } else {
          newFiles.add(mediaItem);
        }
      }

      final int currentPage = _toInt(pagination['page'], fallback: _page);
      final int totalPages = _toInt(pagination['totalPages'], fallback: 1);

      setState(() {
        if (loadMore) {
          _images.addAll(newImages);
          _videos.addAll(newVideos);
          _files.addAll(newFiles);
        } else {
          _images = newImages;
          _videos = newVideos;
          _files = newFiles;
        }

        _page = currentPage;
        _totalPages = totalPages;
        _hasMore = _page < _totalPages;
      });
    } catch (e) {
      if (!loadMore) {
        setState(() {
          _error = e.toString();
        });
      } else {
        if (_page > 1) {
          _page--;
        }
        _showSnackBar('Không tải thêm được media');
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _page++;
    await _fetchMedia(loadMore: true);
  }

  Future<void> _refresh() async {
    await _fetchMedia();
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  String _getCreatedAt(Map<String, dynamic> message) {
    final value = message['createdAt'];
    return value?.toString() ?? '';
  }

  String _getFileName(Map<String, dynamic> attachment) {
    final fileName = attachment['fileName']?.toString() ?? '';
    if (fileName.trim().isNotEmpty) {
      return fileName;
    }

    final url = attachment['url']?.toString() ?? '';
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }

    return 'Tệp đính kèm';
  }

  String _formatFileSize(dynamic value) {
    final size = num.tryParse(value?.toString() ?? '');
    if (size == null) return '';

    if (size < 1024) return '${size.toInt()} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _fileIcon(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return Icons.description;
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
      return Icons.table_chart;
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) return Icons.slideshow;
    if (lower.endsWith('.zip') || lower.endsWith('.rar')) return Icons.folder_zip;
    if (lower.endsWith('.mp3') || lower.endsWith('.wav') || lower.endsWith('.m4a')) {
      return Icons.audio_file;
    }
    if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) {
      return Icons.video_file;
    }
    return Icons.insert_drive_file;
  }

  Future<void> _openUrl(String url) async {
    if (url.trim().isEmpty) {
      _showSnackBar('Link không hợp lệ');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar('Link không hợp lệ');
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _showSnackBar('Không thể mở file');
    }
  }

  Future<void> _copyToClipboard(String text) async {
    if (text.trim().isEmpty) {
      _showSnackBar('Không có link để sao chép');
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Đã sao chép link');
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Ảnh, video, file'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ảnh'),
            Tab(text: 'Video'),
            Tab(text: 'File'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Không tải được media',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchMedia,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: _buildImageTab(),
        ),
        RefreshIndicator(
          onRefresh: _refresh,
          child: _buildVideoTab(),
        ),
        RefreshIndicator(
          onRefresh: _refresh,
          child: _buildFileTab(),
        ),
      ],
    );
  }

  Widget _buildImageTab() {
    if (_images.isEmpty) {
      return _buildEmptyState('Chưa có ảnh');
    }

    return GridView.builder(
      controller: _imageScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: _images.length + (_isLoadingMore ? 1 : 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index >= _images.length) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final item = _images[index];
        final attachment = item['attachment'] as Map<String, dynamic>;
        final url = attachment['url']?.toString() ?? '';

        return GestureDetector(
          onTap: () => _showImagePreview(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey.shade200,
              child: url.isEmpty
                  ? const Center(
                child: Icon(Icons.broken_image_outlined),
              )
                  : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(Icons.broken_image_outlined),
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoTab() {
    if (_videos.isEmpty) {
      return _buildEmptyState('Chưa có video');
    }

    return ListView.separated(
      controller: _videoScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _videos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = _videos[index];
        final message = item['message'] as Map<String, dynamic>;
        final attachment = item['attachment'] as Map<String, dynamic>;

        final url = attachment['url']?.toString() ?? '';
        final fileName = _getFileName(attachment);
        final createdAt = _getCreatedAt(message);
        final duration = attachment['duration']?.toString() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openUrl(url),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.videocam, size: 32),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                        if (duration.isNotEmpty && duration != '0')
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                duration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          createdAt,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileTab() {
    if (_files.isEmpty) {
      return _buildEmptyState('Chưa có file');
    }

    return ListView.separated(
      controller: _fileScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _files.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= _files.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = _files[index];
        final message = item['message'] as Map<String, dynamic>;
        final attachment = item['attachment'] as Map<String, dynamic>;

        final fileName = _getFileName(attachment);
        final sizeText = _formatFileSize(attachment['size']);
        final createdAt = _getCreatedAt(message);
        final url = attachment['url']?.toString() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _fileIcon(fileName),
                color: Colors.blue,
              ),
            ),
            title: Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                [
                  if (sizeText.isNotEmpty) sizeText,
                  if (createdAt.isNotEmpty) createdAt,
                ].join(' • '),
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'open') {
                  await _openUrl(url);
                } else if (value == 'copy') {
                  await _copyToClipboard(url);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(
                  value: 'open',
                  child: Text('Mở file'),
                ),
                PopupMenuItem<String>(
                  value: 'copy',
                  child: Text('Sao chép link'),
                ),
              ],
            ),
            onTap: () => _openUrl(url),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePreview(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      _showSnackBar('Ảnh không hợp lệ');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}