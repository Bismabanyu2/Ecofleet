import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas', style: TextStyle(color: Color(0xFF22C55E))),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: const Center(
        child: Text('Daftar aktivitas akan tampil di sini.'),
      ),
    );
  }
}
