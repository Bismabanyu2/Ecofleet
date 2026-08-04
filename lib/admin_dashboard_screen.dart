import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'app_data.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isTpaView = true;
  String _searchQuery = '';

  // Parser Jenis Kendaraan
  String _getJenisKendaraan(ActivityModel item) {
    final detailLower = item.detail.toLowerCase();
    if (detailLower.contains('[pick up]')) return 'Pick Up';
    if (detailLower.contains('[cator]')) return 'Cator';
    if (detailLower.contains('[truk]')) return 'Truk';
    return 'Kendaraan';
  }

  // Parser Nama Sopir
  String _getDriverName(ActivityModel item) {
    if (item.detail.contains('Sopir:')) {
      final parts = item.detail.split('Sopir:');
      if (parts.length > 1) {
        final namePart = parts[1].split('-')[0];
        return namePart.trim();
      }
    }
    return '-';
  }

  // Parser Nama Operator
  String _getOperatorName(ActivityModel item) {
    if (item.detail.contains('Op:')) {
      final parts = item.detail.split('Op:');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    return '-';
  }

  // Parser Nama Pengawas
  String _getPengawasName(ActivityModel item) {
    if (item.detail.contains('Pengawas:')) {
      final parts = item.detail.split('Pengawas:');
      if (parts.length > 1) {
        return parts[1].replaceAll(')', '').trim();
      }
    }
    return '-';
  }

  Widget _buildImagePreview(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: 100,
        width: double.infinity,
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Text(
          'Tidak ada gambar bukti yang di-upload.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }

    try {
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            alignment: Alignment.center,
            color: Colors.black26,
            child: const Text(
              'Gagal memuat gambar bukti.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        color: Colors.black26,
        child: const Text(
          'Format gambar tidak valid.',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      );
    }
  }

  void _deleteActivity(ActivityModel targetItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data aktivitas ini?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                appData.activities.remove(targetItem);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Data berhasil dihapus'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ActivityModel item) {
    bool isTpa = item.title.toLowerCase().contains('sampah') || item.title.toLowerCase().contains('tpa');
    String jenisKendaraan = _getJenisKendaraan(item);
    String sopirName = _getDriverName(item);
    String secondaryRoleLabel = isTpa ? 'Operator' : 'Pengawas';
    String secondaryRoleName = isTpa ? _getOperatorName(item) : _getPengawasName(item);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          item.title,
          style: const TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jenis Kendaraan: $jenisKendaraan',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nama Sopir: $sopirName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nama $secondaryRoleLabel: $secondaryRoleName',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text('Waktu: ${item.time}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                
                // DIUBAH MENJADI No. Plat:
                Text(
                  'No. Plat: ${item.nomorKendaraan.isNotEmpty ? item.nomorKendaraan : "-"}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                
                const SizedBox(height: 8),
                Text('Detail: ${item.detail}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                const Text(
                  'Bukti Foto Hasil:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImagePreview(item.imageBase64),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteActivity(item);
            },
            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
            label: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(List<ActivityModel> list, String kategori, bool isTpa) async {
    final pdf = pw.Document();
    List<List<dynamic>> tableData = [];

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      String jenisKendaraan = _getJenisKendaraan(item);
      String sopirName = _getDriverName(item);
      String secondaryRoleName = isTpa ? _getOperatorName(item) : _getPengawasName(item);

      pw.Widget imageWidget;
      if (item.imageBase64 != null && item.imageBase64!.isNotEmpty) {
        try {
          final decodedBytes = base64Decode(item.imageBase64!);
          imageWidget = pw.Container(
            width: 50,
            height: 50,
            child: pw.Image(pw.MemoryImage(decodedBytes), fit: pw.BoxFit.cover),
          );
        } catch (e) {
          imageWidget = pw.Text('Error Gambar', style: const pw.TextStyle(fontSize: 8));
        }
      } else {
        imageWidget = pw.Text('Tidak Ada Foto', style: const pw.TextStyle(fontSize: 8));
      }

      tableData.add([
        '${i + 1}',
        jenisKendaraan,
        sopirName,
        secondaryRoleName,
        item.time,
        item.nomorKendaraan.isNotEmpty ? item.nomorKendaraan : '-',
        item.detail,
        imageWidget,
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Laporan Operasional EcoFleet - $kategori',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: [
              'No', 
              'Kendaraan',
              'Nama Sopir', 
              isTpa ? 'Nama Operator' : 'Nama Pengawas', 
              'Waktu', 
              'No Plat', 
              'Detail Informasi', 
              'Bukti Foto'
            ],
            data: tableData,
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {0: pw.Alignment.center, 7: pw.Alignment.center},
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_EcoFleet_$kategori.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tpaList = appData.activities
        .where((act) => act.title.toLowerCase().contains('sampah') || act.title.toLowerCase().contains('tpa'))
        .toList();

    final bbmList = appData.activities
        .where((act) => act.title.toLowerCase().contains('bbm'))
        .toList();

    final currentList = _isTpaView ? tpaList : bbmList;

    final filteredList = currentList.where((item) {
      String jenisKendaraan = _getJenisKendaraan(item);
      String sopirName = _getDriverName(item);
      String secondaryRoleName = _isTpaView ? _getOperatorName(item) : _getPengawasName(item);
      
      return item.detail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.nomorKendaraan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          jenisKendaraan.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          sopirName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          secondaryRoleName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF22C55E)),
            tooltip: 'Ekspor PDF',
            onPressed: () => _exportToPdf(currentList, _isTpaView ? 'Data_TPA' : 'Data_BBM', _isTpaView),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TAB MENU
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTpaView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isTpaView ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Data TPA',
                        style: TextStyle(
                          color: _isTpaView ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isTpaView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isTpaView ? const Color(0xFF22C55E) : const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Data BBM',
                        style: TextStyle(
                          color: !_isTpaView ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PENCARIAN
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari kendaraan, plat, nama, atau detail...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // LISTVIEW
          Expanded(
            child: filteredList.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data tersedia',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      
                      final jenisKendaraan = _getJenisKendaraan(item);
                      final sopirName = _getDriverName(item);
                      final opName = _getOperatorName(item);
                      final pengawasName = _getPengawasName(item);

                      String headerText = '';
                      if (_isTpaView) {
                        headerText = '[$jenisKendaraan] ${item.nomorKendaraan.isNotEmpty ? item.nomorKendaraan : "Tanpa Plat"} • Sopir: $sopirName | Op: $opName';
                      } else {
                        headerText = '[$jenisKendaraan] ${item.nomorKendaraan.isNotEmpty ? item.nomorKendaraan : "Tanpa Plat"} • Sopir: $sopirName | Pengawas: $pengawasName';
                      }

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
                              child: const Icon(Icons.local_shipping, color: Color(0xFF22C55E), size: 20),
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
                                    item.detail,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.time,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.blueAccent, size: 20),
                              onPressed: () => _showDetailDialog(context, item),
                              tooltip: 'Lihat Detail & Bukti Foto',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteActivity(item),
                              tooltip: 'Hapus Data',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}