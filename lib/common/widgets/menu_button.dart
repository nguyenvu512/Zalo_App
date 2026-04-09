import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showArrow;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const MenuButton({
    super.key,
    required this.icon,
    required this.label,
    this.showArrow = false,
    this.onTap,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon bên trái
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 12),

              // Label ở giữa (flexible để chiếm hết space)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? Colors.black87,
                  ),
                ),
              ),

              // Mũi tên (tuỳ chọn)
              if (showArrow)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}