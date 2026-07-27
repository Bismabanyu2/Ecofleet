import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // <-- Cukup gunakan import ini saja
import 'app_data.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _sopirController = TextEditingController();
  
  String? _selectedJenisSampah;
  final List<String> _jenisSampahList = [
    'Sampah Organik (Basah/Sisa Makanan)',
    'Sampah Anorganik (Plastik/Kertas/Logam)',
    'Sampah B3 (Bahan Berbahaya & Beracun)',
    'Sampah Campur / Residu'
  ];

  XFile? _selectedImage; // <-- 2. Variabel penampung file gambar
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

  // 3. Fungsi Asli untuk Membuka Galeri/File Manager
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti sampah berhasil dipilih!'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _simpanData() {
    if (_volumeController.text.isEmpty || _selectedJenisSampah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Volume dan Jenis Sampah wajib diisi/dipilih!'), backgroundColor: Colors.red),
      );
      return;
    }

    appData.addActivity(ActivityModel(
      title: 'Pembuangan Sampah Berhasil',
      time: _formattedTime,
      detail: '${_volumeController.text} Kg (${_selectedJenisSampah!.split(' ')[0]})',
      iconCode: Icons.delete_sweep.codePoint,
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
          'Input Pembuangan Sampah',
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

                  const Text('Volume Sampah (Kg)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _volumeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.delete_outline, color: Colors.grey),
                      hintText: '0.00',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Jenis Sampah', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedJenisSampah,
                        hint: const Text('Pilih Jenis Sampah Lengkap', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        isExpanded: true,
                        items: _jenisSampahList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedJenisSampah = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Waktu Pengangkutan (Realtime)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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

                  const Text('Bukti Foto Pembuangan', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  
                  // 4. Widget GestureDetector Upload Diganti Disini
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
                                ? 'Upload Foto Bukti Timbangan/Sampah' 
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
                            const Text('Klik untuk ambil dari galeri/folder', style: TextStyle(color: Colors.grey, fontSize: 11)),
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