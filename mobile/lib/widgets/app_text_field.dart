import 'package:flutter/material.dart';

/// A styled text field used across the auth screens. Picks up the global
/// [InputDecorationTheme], so it stays visually consistent everywhere.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
      ),
      validator: validator,
    );
  }
}
