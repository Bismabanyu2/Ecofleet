import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firebase Firestore
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
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _pengawasController = TextEditingController();
  
  // Pilihan Shift
  String? _selectedShift;
  final List<String> _shiftList = ['Pagi', 'Malam'];

  // Pilihan Jenis BBM
  String? _selectedJenisBbm;
  final List<String> _jenisBbmList = ['Subsidi', 'Non-Subsidi', 'Pertamina Dex'];

  // Pilihan Jenis Kendaraan
  String? _selectedJenisKendaraan;
  final List<String> _jenisKendaraanList = ['Pick Up', 'Truk', 'Cator'];

  XFile? _selectedImage; 
  final ImagePicker _picker = ImagePicker();

  String _formattedTime = '';

  @override
  void initState() {
    super.initState();
    _updateRealtimeTime();
  }

  @override
  void dispose() {
    _literController.dispose();
    _hargaController.dispose();
    _sopirController.dispose();
    _lokasiController.dispose();
    _pengawasController.dispose();
    super.dispose();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti BBM berhasil dipilih!'), duration: Duration(seconds: 1)),
      );
    }
  }

  Future<void> _simpanData() async {
    if (_literController.text.isEmpty || _selectedShift == null || _selectedJenisBbm == null || _selectedJenisKendaraan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis Kendaraan, BBM, Liter, dan Shift wajib diisi/dipilih!'), backgroundColor: Colors.red),
      );
      return;
    }

    String lokasi = _lokasiController.text.isNotEmpty ? _lokasiController.text : "SPBU";
    String sopir = _sopirController.text.isNotEmpty ? _sopirController.text : "-";
    String pengawas = _pengawasController.text.isNotEmpty ? _pengawasController.text : "-";
    String harga = _hargaController.text.isNotEmpty ? _hargaController.text : "0";

    String? imageBase64String;
    if (_selectedImage != null) {
      try {
        Uint8List imageBytes = await _selectedImage!.readAsBytes();
        if (imageBytes.isNotEmpty) {
          imageBase64String = base64Encode(imageBytes);
          debugPrint("SUKSES: Gambar BBM berhasil diubah ke Base64");
        }
      } catch (e) {
        debugPrint("GAGAL membaca byte gambar BBM: $e");
      }
    }

    String detailText = '[$_selectedJenisKendaraan] ${_literController.text} Liter ($_selectedJenisBbm - Rp $harga) di $lokasi - Shift $_selectedShift - Sopir: $sopir - Pengawas: $pengawas';

    // 1. SIMPAN DATA KE CLOUD FIREBASE FIRESTORE (UNTUK DASHBOARD ADMIN)
    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'title': 'Input BBM Berhasil',
        'time': _formattedTime,
        'detail': detailText,
        'nomorKendaraan': appData.nomorKendaraan,
        'imageBase64': imageBase64String,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("SUKSES: Data BBM berhasil dikirim ke Firebase Firestore");
    } catch (e) {
      debugPrint("GAGAL mengirim data BBM ke Firestore: $e");
    }

    // 2. SIMPAN DATA KE MEMORI LOKAL APP
    appData.addActivity(ActivityModel(
      title: 'Input BBM Berhasil',
      time: _formattedTime,
      detail: detailText,
      iconCode: Icons.local_gas_station.codePoint,
      imageBase64: imageBase64String,
      nomorKendaraan: appData.nomorKendaraan,
    ));

    if (!mounted) return;

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
                  // JENIS KENDARAAN
                  const Text('Jenis Kendaraan', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                        value: _selectedJenisKendaraan,
                        hint: const Text('Pilih Kendaraan (Pick Up / Truk / Cator)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        isExpanded: true,
                        items: _jenisKendaraanList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedJenisKendaraan = newValue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  const Text('Nama Pengawas', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _pengawasController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.grey),
                      hintText: 'Masukkan nama pengawas',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Shift Kerja', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                        value: _selectedShift,
                        hint: const Text('Pilih Shift (Pagi / Malam)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        isExpanded: true,
                        items: _shiftList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedShift = newValue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // JENIS BBM
                  const Text('Jenis BBM', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
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
                        value: _selectedJenisBbm,
                        hint: const Text('Pilih Jenis BBM (Subsidi / Non-Subsidi / Pertamina Dex)', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        isExpanded: true,
                        items: _jenisBbmList.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedJenisBbm = newValue),
                      ),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(height: 12),
                                Icon(Icons.camera_alt_outlined, color: Color(0xFF22C55E), size: 36),
                                SizedBox(height: 8),
                                Text(
                                  'Upload Foto Bukti Pengisian BBM',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 2),
                                Text('Klik untuk ambil dari folder/galeri (PNG, JPG)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                SizedBox(height: 12),
                              ],
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.network(
                                          _selectedImage!.path,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : FutureBuilder<Uint8List>(
                                          future: _selectedImage!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const SizedBox(
                                              height: 160,
                                              child: Center(child: CircularProgressIndicator()),
                                            );
                                          },
                                        ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Terpilih: ${_selectedImage!.name}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.edit, size: 14),
                                      label: const Text('Ganti', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                    ),
                                  ],
                                ),
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