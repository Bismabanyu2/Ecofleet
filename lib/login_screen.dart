import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_styles.dart';
import 'register_screen.dart';
import 'main.dart';
import 'app_data.dart';
import 'admin_dashboard_screen.dart'; // Pastikan di-import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Proses Login dengan Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Cek apakah email yang login adalah akun admin khusus
      if (_emailController.text.trim() == 'admin@ecofleet.com') {
        // Muat semua data aktivitas dari seluruh user untuk admin
        await appData.loadUserData();

        if (!mounted) return;
        // Masuk ke Tampilan Dashboard Admin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        // Muat data profil & aktivitas pengguna dari database Firestore untuk sopir biasa
        await appData.loadUserData();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login Gagal'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppStyles.lightGreenBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_shipping, size: 50, color: Color.fromARGB(255, 25, 122, 52)),
              ),
              const SizedBox(height: 16),
              const Text('EcoFleet Login', style: AppStyles.titleStyle),
              const SizedBox(height: 4),
              const Text('Masuk menggunakan akun anda yang sudah terdaftar', style: AppStyles.subtitleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      decoration: AppStyles.inputDecoration(hintText: 'Masukkan email', prefixIcon: Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: AppStyles.inputDecoration(hintText: 'Masukkan password', prefixIcon: Icons.lock_outline),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppStyles.darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Masuk', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun? ", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Daftar di sini',
                      style: TextStyle(color: AppStyles.primaryGreen, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}