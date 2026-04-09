// lib/widgets/common/menu_button_group.dart
import 'package:flutter/material.dart';
import 'package:zalo_mobile_app/common/widgets/menu_button.dart';

class MenuButtonGroup extends StatelessWidget {
  final List<MenuButton> buttons;

  const MenuButtonGroup({
    super.key,
    required this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(buttons.length, (index) {
        final isFirst = index == 0;
        final isLast = index == buttons.length - 1;
        final btn = buttons[index];

        // Lấy radius từ button, fallback về 30 nếu không có
        final double r = btn.borderRadius?.topLeft.x ?? 30;

        final radius = BorderRadius.only(
          topLeft: isFirst ? Radius.circular(r) : Radius.zero,
          topRight: isFirst ? Radius.circular(r) : Radius.zero,
          bottomLeft: isLast ? Radius.circular(r) : Radius.zero,
          bottomRight: isLast ? Radius.circular(r) : Radius.zero,
        );

        return Column(
          children: [
            MenuButton(
              icon: btn.icon,
              label: btn.label,
              showArrow: btn.showArrow,
              onTap: btn.onTap,
              iconColor: btn.iconColor,
              textColor: btn.textColor,
              backgroundColor: btn.backgroundColor,
              borderRadius: radius,
            ),
            if (!isLast)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        );
      }),
    );
  }
}