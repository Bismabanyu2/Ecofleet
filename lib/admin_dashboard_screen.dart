import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0 = Sampah TPA, 1 = BBM, 2 = Servis Kendaraan
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper mendapatkan jenis kendaraan dari string detail
  String _getJenisKendaraan(String detail) {
    if (detail.startsWith('[')) {
      int closeIndex = detail.indexOf(']');
      if (closeIndex != -1) {
        return detail.substring(1, closeIndex);
      }
    }
    return 'Kendaraan Ops';
  }

  // Helper mendapatkan nama sopir dari string detail
  String _getDriverName(String detail) {
    if (detail.contains('Sopir:')) {
      final parts = detail.split('Sopir:');
      if (parts.length > 1) {
        final driverPart = parts[1].trim();
        final endPart = driverPart.split(' - ')[0].split(' • ')[0];
        return endPart.isNotEmpty ? endPart : 'Sopir';
      }
    }
    return 'Sopir';
  }

  // FUNGSI EKSPOR LAPORAN KE PDF
  Future<void> _exportPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    String tabTitle = _selectedTab == 0
        ? 'Laporan Pembuangan Sampah TPA'
        : _selectedTab == 1
            ? 'Laporan Pengisian BBM'
            : 'Laporan Servis Kendaraan';

    final pdfData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final time = data['time'] ?? '-';
      final plat = data['nomorKendaraan'] ?? '-';
      final detail = data['detail'] ?? '-';
      final sopir = _getDriverName(detail);
      final jenis = _getJenisKendaraan(detail);
      return [time, plat, jenis, sopir, detail];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EcoFleet - $tabTitle',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'Total Data: ${pdfData.length}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Waktu', 'No. Plat', 'Jenis', 'Sopir', 'Detail Keterangan'],
              data: pdfData,
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_EcoFleet_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  // FUNGSI KONFIRMASI LOGOUT / KELUAR
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Konfirmasi Keluar', style: TextStyle(color: Colors.white)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Dialog Tampil Detail Foto & Keterangan
  void _showDetailDialog(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Detail Aktivitas';
    final time = data['time'] ?? '-';
    final detail = data['detail'] ?? '-';
    final plat = data['nomorKendaraan'] ?? 'Tanpa Plat';
    final imageBase64 = data['imageBase64'];

    showDialog(
      context: context,
      builder: (context) {
        Uint8List? imageBytes;
        if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
          try {
            imageBytes = base64Decode(imageBase64);
          } catch (e) {
            debugPrint("Error decode base64: $e");
          }
        }

        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  
                  // Label Plat Nomor
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Plat: $plat',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Waktu: $time', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  const Text('Detail Keterangan:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(detail, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                  const SizedBox(height: 16),

                  // Tampilkan Foto Bukti
                  if (imageBytes != null) ...[
                    const Text('Bukti Foto:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        imageBytes,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ] else ...[
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada foto bukti',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Theme gelap khas Admin
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Dashboard Admin (Realtime)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF22C55E)),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Memperbarui data...'), duration: Duration(milliseconds: 800)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Keluar / Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          List<QueryDocumentSnapshot> filteredDocs = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docs = snapshot.data!.docs;

            filteredDocs = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              final detail = (data['detail'] ?? '').toString().toLowerCase();
              final plat = (data['nomorKendaraan'] ?? '').toString().toLowerCase();

              bool matchesTab = false;
              if (_selectedTab == 0) {
                matchesTab = title.contains('sampah') || title.contains('tpa');
              } else if (_selectedTab == 1) {
                matchesTab = title.contains('bbm');
              } else {
                matchesTab = title.contains('servis') || title.contains('service');
              }

              bool matchesSearch = detail.contains(_searchQuery.toLowerCase()) ||
                  plat.contains(_searchQuery.toLowerCase());

              return matchesTab && matchesSearch;
            }).toList();
          }

          return Column(
            children: [
              const SizedBox(height: 12),

              // Pilihan Tab (TPA, BBM, Servis)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Data TPA',
                            style: TextStyle(
                              color: _selectedTab == 0 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Data BBM',
                            style: TextStyle(
                              color: _selectedTab == 1 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == 2 ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Data Servis',
                            style: TextStyle(
                              color: _selectedTab == 2 ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Baris Pencarian & Tombol Ekspor PDF
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cari plat, sopir, atau ket...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, color: Colors.white38),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: filteredDocs.isEmpty ? null : () => _exportPdf(filteredDocs),
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.black, size: 18),
                      label: const Text(
                        'PDF',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Daftar Item Laporan
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)));
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada data laporan yang sesuai',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final detail = data['detail'] ?? '';
                        final time = data['time'] ?? '';
                        final plat = data['nomorKendaraan'] ?? '';

                        final jenisKendaraan = _getJenisKendaraan(detail);
                        final sopirName = _getDriverName(detail);

                        String headerText = '[$jenisKendaraan] ${plat.isNotEmpty ? plat : "Tanpa Plat"} • Sopir: $sopirName';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _selectedTab == 0
                                      ? Icons.delete_sweep
                                      : _selectedTab == 1
                                          ? Icons.local_gas_station
                                          : Icons.build,
                                  color: const Color(0xFF22C55E),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      headerText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      detail,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      time,
                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, color: Colors.blueAccent, size: 20),
                                onPressed: () => _showDetailDialog(context, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  // Hapus data langsung dari Firestore
                                  await doc.reference.delete();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Data berhasil dihapus')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}