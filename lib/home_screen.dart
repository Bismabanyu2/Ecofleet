import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bbm_screen.dart';
import 'trash_screen.dart';
import 'service_screen.dart'; // Import layar servis
import 'login_screen.dart';
import 'history_screen.dart';
import 'app_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  int _secondsRemaining = 31500; 
  bool _isShiftEnded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        if (!_isShiftEnded) {
          setState(() {
            _isShiftEnded = true;
          });
          _timer?.cancel();
          _showShiftEndedDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showShiftEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Shift Selesai!'),
          content: const Text('Waktu kerja 9 jam Anda hari ini telah berakhir. Silakan selesaikan laporan akhir atau istirahat.'),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showGantiKendaraanDialog(BuildContext context) {
    final TextEditingController kendaraanController = TextEditingController(text: appData.nomorKendaraan);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ganti Plat Nomor Kendaraan'),
          content: TextField(
            controller: kendaraanController,
            decoration: const InputDecoration(
              labelText: 'Nomor Kendaraan',
              hintText: 'Contoh: B 5678 XYZ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
              onPressed: () {
                appData.updateKendaraan(kendaraanController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nomor kendaraan berhasil diubah!')),
                );
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                
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
        final latestActivity = appData.activities.isNotEmpty ? appData.activities.first : null;

        ImageProvider avatarProvider;
        if (appData.fotoBase64 != null && appData.fotoBase64!.isNotEmpty) {
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
              children: [
                CircleAvatar(
                  backgroundImage: avatarProvider,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appData.nama,
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appData.jabatan,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.green),
                onPressed: () => _showLogoutDialog(context),
                tooltip: 'Pengaturan / Keluar',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang, ${appData.nama.split(' ')[0]}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Siap untuk menjaga kebersihan kota hari ini?',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                
                // Status Shift Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isShiftEnded ? Colors.grey.shade700 : const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isShiftEnded ? 'Shift Telah Berakhir' : 'Sisa Waktu Shift Hari Ini',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                _isShiftEnded ? '00:00:00' : _formatCountdown(_secondsRemaining),
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          GestureDetector(
                            onTap: () {
                              _showGantiKendaraanDialog(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Kendaraan: ${appData.nomorKendaraan}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit, color: Colors.white70, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.local_shipping, color: Colors.white24, size: 70),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. MENU INPUT BBM
                _buildMenuCard(
                  icon: Icons.local_gas_station_outlined,
                  title: 'Input BBM',
                  subtitle: 'Catat pengisian bahan bakar kendaraan harian.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BbmScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 2. MENU INPUT PEMBUANGAN SAMPAH
                _buildMenuCard(
                  icon: Icons.delete_outline,
                  title: 'Input Pembuangan Sampah',
                  subtitle: 'Laporkan volume sampah yang berhasil diangkut.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrashScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 3. MENU INPUT SERVIS KENDARAAN (BARU)
                _buildMenuCard(
                  icon: Icons.build_outlined,
                  title: 'Input Servis Kendaraan',
                  subtitle: 'Catat riwayat perbaikan dan servis berkala kendaraan.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ServiceScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terakhir',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (latestActivity != null)
                  Container(
                    padding: const EdgeInsets.all(12),
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
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconData(latestActivity.iconCode, fontFamily: 'MaterialIcons'),
                            color: const Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestActivity.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${latestActivity.time} • ${latestActivity.detail}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuCard({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF22C55E)),
                ),
                const Icon(Icons.arrow_forward, color: Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}