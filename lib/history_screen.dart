import 'dart:convert';
import 'package:flutter/material.dart';
import 'app_data.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _showImagePreview(BuildContext context, String? imageBase64, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageBase64 != null && imageBase64.isNotEmpty
                  ? Image.memory(base64Decode(imageBase64), fit: BoxFit.cover)
                  : const Center(child: Text('Tidak ada gambar bukti.', style: TextStyle(color: Colors.grey))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Color(0xFF22C55E))),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Apakah Anda yakin ingin menghapus riwayat aktivitas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                appData.removeActivity(activity);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Riwayat berhasil dihapus'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Semua Aktivitas & Riwayat', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: AnimatedBuilder(
        animation: appData,
        builder: (context, child) {
          final activities = appData.activities;

          if (activities.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada riwayat aktivitas.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              final hasImage = activity.imageBase64 != null && activity.imageBase64!.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Ikon Status di Kiri
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        activity.title.contains('BBM') ? Icons.local_gas_station : Icons.delete_sweep,
                        color: const Color(0xFF22C55E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // 2. Teks Keterangan di Tengah
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activity.time} • ${activity.nomorKendaraan}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity.detail,
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 3. Thumbnail Gambar di Kanan (Jika ada)
                    if (hasImage) ...[
                      GestureDetector(
                        onTap: () => _showImagePreview(context, activity.imageBase64, activity.title),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(activity.imageBase64!),
                            width: 45,
                            height: 45,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // 4. TOMBOL HAPUS (Pastikan ini ada di luar kondisi gambar)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                      onPressed: () => _confirmDelete(context, activity),
                      tooltip: 'Hapus Riwayat',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}