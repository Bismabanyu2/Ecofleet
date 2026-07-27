import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- Perbaikan import di sini
import 'app_data.dart';

class BbmScreen extends StatefulWidget {
  const BbmScreen({super.key});

  @override
  State<BbmScreen> createState() => _BbmScreenState();
}

class _BbmScreenState extends State<BbmScreen> {
  final TextEditingController _literController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _sopirController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController(); // <-- 1. Controller untuk Lokasi Pengisian
  
  XFile? _selectedImage; 
  final ImagePicker _picker = ImagePicker();

  String _formattedTime = '';

  @override
  void initState() {
    super.initState();
    _updateRealtimeTime();
  }

  void _updateRealtimeTime() {
    final now = DateTime.now();
    setState(() {
      _formattedTime = '${_getDayName(now.weekday)}, ${now.day} ${_getMonthName(now.month)} ${now.year} pukul ${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    });
  }

  String _getDayName(int weekday) {
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return months[month - 1];
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti BBM berhasil dipilih!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _simpanData() {
    if (_literController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah BBM (Liter) wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    appData.addActivity(ActivityModel(
      title: 'Input BBM Berhasil',
      time: _formattedTime,
      detail: '${_literController.text} Liter di ${_lokasiController.text.isNotEmpty ? _lokasiController.text : "SPBU"}',
      iconCode: Icons.local_gas_station.codePoint,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF34D399), size: 20),
            SizedBox(width: 8),
            Text(
              'Data berhasil disimpan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF064E3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input BBM',
          style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Sopir', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _sopirController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                      hintText: 'Masukkan nama sopir',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Jumlah BBM (Liter)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _literController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.local_gas_station_outlined, color: Colors.grey),
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Harga BBM (Rp)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _hargaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      hintText: '0',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // <-- 2. Inputan Baru: Lokasi Pengisian BBM -->
                  const Text('Lokasi Pengisian BBM', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lokasiController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                      hintText: 'Contoh: SPBU Pertamina Jl. Sudirman',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Waktu Pengisian (Realtime)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(_formattedTime, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Bukti Pengisian', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Color(0xFF22C55E), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            _selectedImage == null 
                                ? 'Upload Foto Bukti Pengisian BBM' 
                                : 'Terpilih: ${_selectedImage!.name}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13, 
                              color: _selectedImage == null ? Colors.black : Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_selectedImage == null) ...[
                            const SizedBox(height: 2),
                            const Text('Klik untuk ambil dari folder/galeri (PNG, JPG)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ]
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _simpanData,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.save_outlined, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Simpan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}