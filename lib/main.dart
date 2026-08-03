import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'app_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inisialisasi Firebase menggunakan kredensial Web asli dari Firebase Console
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBcFto_XVAXGsoPc10SH0tRkAtE-Dkaz3c",
        authDomain: "bisma-ed323.firebaseapp.com",
        projectId: "bisma-ed323",
        storageBucket: "bisma-ed323.firebasestorage.app",
        messagingSenderId: "828240171048",
        appId: "1:828240171048:web:e0b4acfbfdded6cc01251d",
      ),
    );
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  runApp(const EcoFleetApp());
}

class EcoFleetApp extends StatelessWidget {
  const EcoFleetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoFleet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}

// Backwards-compatible alias for tests expecting `MyApp`.
class MyApp extends EcoFleetApp {
  const MyApp({super.key});
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFF22C55E),
            unselectedItemColor: Colors.grey,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

// Halaman History / Lihat Semua Aktivitas (Sudah Diperbarui dengan Thumbnail & Tombol Hapus)
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Fungsi untuk menampilkan pop-up preview gambar ukuran penuh saat thumbnail ditekan
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
                  ? Image.memory(
                      base64Decode(imageBase64),
                      fit: BoxFit.cover,
                    )
                  : const Center(
                      child: Text(
                        'Tidak ada gambar bukti yang dilampirkan.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
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

  // Fungsi konfirmasi hapus riwayat (CRUD: Delete)
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
    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        final activities = appData.activities;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            title: const Text(
              'Semua Aktivitas & Riwayat',
              style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
            ),
          ),
          body: activities.isEmpty
              ? const Center(
                  child: Text(
                    'Belum ada riwayat aktivitas.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final item = activities[index];
                    final hasImage = item.imageBase64 != null && item.imageBase64!.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Ikon Status di Kiri
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconData(item.iconCode, fontFamily: 'MaterialIcons'),
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
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.time} • ${item.detail}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 3. Thumbnail Gambar di Kanan (Jika ada)
                          if (hasImage) ...[
                            GestureDetector(
                              onTap: () => _showImagePreview(context, item.imageBase64, item.title),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(item.imageBase64!),
                                  width: 45,
                                  height: 45,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // 4. Tombol Hapus (CRUD: Delete) di Pojok Kanan
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                            onPressed: () => _confirmDelete(context, item),
                            tooltip: 'Hapus Riwayat',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}