import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'app_data.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _webImageBytes;

  // Fungsi untuk mengganti foto profil, konversi ke Base64, dan simpan permanen
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      
      // Konversi bytes gambar ke string Base64
      String base64Image = base64Encode(bytes);

      setState(() {
        _webImageBytes = bytes;
        appData.fotoProfil = image.path; 
      });

      // Simpan permanen ke Firestore
      await appData.updateProfile(
        newNama: appData.nama,
        newJabatan: appData.jabatan,
        newNip: appData.nip,
        newKontak: appData.kontak,
        newFoto: image.path,
        newBase64: base64Image,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil disimpan secara permanen!')),
      );
    }
  }

  void _showEditProfileModal(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: appData.nama);
    final TextEditingController jabatanController = TextEditingController(text: appData.jabatan);
    final TextEditingController nipController = TextEditingController(text: appData.nip);
    final TextEditingController kontakController = TextEditingController(text: appData.kontak);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profil Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jabatanController,
                decoration: const InputDecoration(labelText: 'Jabatan', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nipController,
                decoration: const InputDecoration(labelText: 'NIP / Nomor Karyawan', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kontakController,
                decoration: const InputDecoration(labelText: 'Info Kontak', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                  onPressed: () {
                    appData.updateProfile(
                      newNama: nameController.text,
                      newJabatan: jabatanController.text,
                      newNip: nipController.text,
                      newKontak: kontakController.text,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil berhasil diperbarui!')),
                    );
                  },
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // --- FUNGSI LOGOUT KELUAR AKUN ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar Akun'),
          content: const Text('Apakah Anda yakin ingin keluar dari aplikasi EcoFleet?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // Logout dari Firebase Auth
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                
                // Kembali ke halaman Login dan hapus semua riwayat navigasi sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        // Tentukan sumber gambar berdasarkan ketersediaan Base64 atau URL
        ImageProvider avatarProvider;
        if (_webImageBytes != null) {
          avatarProvider = MemoryImage(_webImageBytes!);
        } else if (appData.fotoBase64 != null && appData.fotoBase64!.isNotEmpty) {
          avatarProvider = MemoryImage(base64Decode(appData.fotoBase64!));
        } else if (appData.fotoProfil.startsWith('http') || appData.fotoProfil.startsWith('blob:')) {
          avatarProvider = NetworkImage(appData.fotoProfil);
        } else {
          avatarProvider = AssetImage(appData.fotoProfil);
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            title: Row(
              children: const [
                Icon(Icons.person_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'EcoFleet',
                  style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              // IKON BERGERIGI (SETTINGS) DI KANAN ATAS UNTUK LOGOUT
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.black),
                onPressed: () => _showLogoutDialog(context),
                tooltip: 'Pengaturan / Keluar',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: avatarProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  appData.nama,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appData.jabatan,
                    style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 20),

                // NIP Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.badge_outlined, color: Color(0xFF22C55E)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NIP / Nomor Karyawan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(appData.nip, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Kontak Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.phone_outlined, color: Color(0xFF22C55E)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Info Kontak', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(appData.kontak, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Row Statistik
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.local_shipping_outlined, color: Colors.white),
                            SizedBox(height: 12),
                            Text('Total Rute', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('1.240', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.verified_user_outlined, color: Color(0xFF22C55E)),
                            SizedBox(height: 12),
                            Text('Skor Keamanan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            SizedBox(height: 4),
                            Text('98%', style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tombol Edit Profil
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showEditProfileModal(context),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text('Edit Profil', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Terakhir diperbarui: Hari ini',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}