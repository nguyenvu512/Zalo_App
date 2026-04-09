import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPasswordField;

  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.isPasswordField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label ở trên
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color.fromARGB(255, 73, 73, 73),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Ô input bên dưới
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            obscureText: isPasswordField,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        )
      ],
    );
  }
}