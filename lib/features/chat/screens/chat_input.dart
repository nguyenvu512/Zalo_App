import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zalo_mobile_app/features/chat/screens/emoji_panel.dart';
import 'package:zalo_mobile_app/features/chat/screens/sticker_picker.dart';
import 'package:file_picker/file_picker.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function({
    String? text,
    File? file,
    required String type,
  }) onSend;
  final ValueChanged<double>? onHeightChanged;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onHeightChanged,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _animation;

  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;

  static const double _baseBottomBarHeight = 86;
  static const double _emojiHeight = 280;
  static const double _expandPanelHeight = 86;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyHeight();
    });
  }

  void _notifyHeight() {
    double height = _baseBottomBarHeight;

    if (_showEmoji) {
      height += _emojiHeight;
    }

    if (_expanded) {
      height += _expandPanelHeight;
    }

    widget.onHeightChanged?.call(height);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
    }

    setState(() => _expanded = !_expanded);
    _expanded ? _animController.forward() : _animController.reverse();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyHeight();
    });
  }

  void _toggleEmoji() {
    if (_expanded) {
      _toggleExpand();
    }

    setState(() => _showEmoji = !_showEmoji);

    if (_showEmoji) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyHeight();
    });
  }

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, emoji);
    widget.controller.text = newText;
    widget.controller.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
  }

  Future<void> _pickImage() async {
    _toggleExpand();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      widget.onSend(type: "image", file: file);
    }
  }

  Future<void> _pickFile() async {
    if (_expanded) {
      _toggleExpand();
    }

    if (_showEmoji) {
      setState(() => _showEmoji = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyHeight();
      });
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.first;

      if (picked.path != null) {
        final file = File(picked.path!);
        print(file);
        widget.onSend(
          file: file,
          type: "file",
        );
      }
    }
  }

  Future<void> _pickSticker() async {
    if (_expanded) {
      _toggleExpand();
    }

    if (_showEmoji) {
      setState(() => _showEmoji = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyHeight();
      });
    }

    final selectedUrl = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StickerPicker();
      },
    );

    if (selectedUrl != null) {
      widget.onSend(
        text: selectedUrl,
        type: "sticker",
      );
    }
  }

  Widget _buildOptionButton(
      IconData icon,
      String label,
      Color color,
      VoidCallback? onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
        top: 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizeTransition(
                  sizeFactor: _animation,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOptionButton(
                            Icons.image, "Hình ảnh", Colors.green, _pickImage),
                        _buildOptionButton(
                          Icons.emoji_emotions,
                          "Sticker",
                          Colors.yellow,
                          _pickSticker,
                        ),
                        _buildOptionButton(
                            Icons.mic, "Audio", Colors.orange, _pickImage),
                        _buildOptionButton(Icons.insert_drive_file, "File",
                            Colors.blue, _pickFile),
                        _buildOptionButton(Icons.videocam, "Video",
                            Colors.purple, _pickImage),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleExpand,
                        child: AnimatedRotation(
                          turns: _expanded ? 0.125 : 0,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.black87, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: widget.controller,
                          style: const TextStyle(color: Colors.black87),
                          onTap: () {
                            if (_showEmoji) {
                              setState(() => _showEmoji = false);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _notifyHeight();
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Nhập tin nhắn...",
                            hintStyle:
                            TextStyle(color: Colors.black87.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: _toggleEmoji,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _showEmoji
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: Colors.black87,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: () {
                          final text = widget.controller.text.trim();
                          if (text.isEmpty) return;
                          widget.onSend(text: text, type: "text");
                          widget.controller.clear();
                          if (_showEmoji) {
                            setState(() => _showEmoji = false);
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              _notifyHeight();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.send,
                              color: Colors.white.withOpacity(0.8), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showEmoji)
                  SizedBox(
                    height: 280,
                    child: EmojiPanel(
                      onEmojiSelected: (emoji) {
                        _insertEmoji(emoji.emoji);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}