import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPanel extends StatelessWidget {
  final void Function(Emoji emoji) onEmojiSelected;

  const EmojiPanel({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    const outerBg = Color(0x22FFFFFF);
    const border = Color(0x33FFFFFF);

    final themed = Theme.of(context).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      cardColor: Colors.transparent,
      dialogBackgroundColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: Theme.of(context).colorScheme.copyWith(
        surface: Colors.transparent,
        primary: Colors.white70,
        secondary: Colors.white70,
      ),
    );

    return Theme(
      data: themed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: outerBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: EmojiPicker(
              onEmojiSelected: (_, emoji) => onEmojiSelected(emoji),
              config: const Config(
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: Colors.transparent,
                  columns: 8,
                  emojiSizeMax: 28,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: Colors.transparent,
                  iconColor: Colors.black54,
                  iconColorSelected: Colors.black87,
                  indicatorColor: Colors.white38,
                  dividerColor: Colors.white24,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: Colors.transparent,
                  // buttonColor: Colors.transparent,
                  buttonIconColor: Colors.black45,
                  hintText: '',
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  showBackspaceButton: false,
                  showSearchViewButton: false,
                  backgroundColor: Colors.transparent,
                  buttonIconColor: Colors.black45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}