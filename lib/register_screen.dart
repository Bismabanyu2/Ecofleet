import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    // Validasi kosong
    if (_namaController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.red),
      );
      return;
    }

    // Validasi minimal password 6 karakter sesuai standar Firebase
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password minimal harus 6 karakter!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Buat akun Auth di Firebase
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Simpan data profil awal ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'nama': _namaController.text.trim(),
        'jabatan': 'Fleet Driver Senior',
        'nip': _nipController.text.trim().isEmpty ? 'EMP-2024-001' : _nipController.text.trim(),
        'kontak': _emailController.text.trim(),
        'fotoProfil': 'https://i.pravatar.cc/150?img=12',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      // Terjemahkan pesan error umum agar mudah dipahami
      String errorMessage = 'Registrasi Gagal';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else {
        errorMessage = e.message ?? 'Terjadi kesalahan.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
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
      appBar: AppBar(
        backgroundColor: AppStyles.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Daftar Akun EcoFleet', style: AppStyles.titleStyle),
              const SizedBox(height: 4),
              const Text('Daftar akun online dengan Firebase', style: AppStyles.subtitleStyle, textAlign: TextAlign.center),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _namaController,
                      decoration: AppStyles.inputDecoration(hintText: 'Masukkan nama lengkap'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Email Aktif', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      decoration: AppStyles.inputDecoration(hintText: 'Masukkan email'),
                    ),
                    const SizedBox(height: 16),
                    const Text('NIP / Nomor Karyawan', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nipController,
                      decoration: AppStyles.inputDecoration(hintText: 'Contoh: EMP-2024-100'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: AppStyles.inputDecoration(hintText: 'Buat password baru'),
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
                        onPressed: _isLoading ? null : _register,
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Daftar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}