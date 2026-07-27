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

// Halaman History / Lihat Semua Aktivitas
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appData,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F9FA),
            elevation: 0,
            title: const Text(
              'Semua Aktivitas & Riwayat',
              style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: appData.activities.length,
            itemBuilder: (context, index) {
              final item = appData.activities[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(item.iconCode, fontFamily: 'MaterialIcons'),
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                    const SizedBox(width: 12),
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