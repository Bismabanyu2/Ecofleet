import 'package:flutter/material.dart';

class AppStyles {
  AppStyles._();

  static const Color primaryGreen = Color(0xFF1E8E3E);
  static const Color darkGreen = Color(0xFF166F2A);
  static const Color lightGreenBg = Color(0xFFE8F5EA);
  static const Color scaffoldBg = Color(0xFFF7F7F7);

  static const TextStyle titleStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black);
  static const TextStyle subtitleStyle = TextStyle(fontSize: 13, color: Colors.black54);

  static const BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.all(Radius.circular(12)),
    boxShadow: [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
  );

  static InputDecoration inputDecoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      filled: true,
      fillColor: const Color(0xFFF2F6F2),
    );
  }
}
