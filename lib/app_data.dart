import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String title;
  final String time;
  final String detail;
  final int iconCode;

  ActivityModel({
    required this.title,
    required this.time,
    required this.detail,
    required this.iconCode,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'detail': detail,
        'iconCode': iconCode,
      };

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        title: json['title'] ?? '',
        time: json['time'] ?? '',
        detail: json['detail'] ?? '',
        iconCode: json['iconCode'] ?? Icons.history.codePoint,
      );
}

class AppData extends ChangeNotifier {
  String nama = 'Budi Santoso';
  String jabatan = 'Fleet Driver Senior';
  String nip = 'EMP-2024-089';
  String kontak = '+62 812-3456-7890';
  String fotoProfil = 'https://i.pravatar.cc/150?img=12';
  
  // Variabel untuk menyimpan string Base64 gambar profil
  String? fotoBase64; 

  // Tambahan variabel nomor kendaraan
  String nomorKendaraan = "B 1234 ABC"; 

  List<ActivityModel> activities = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppData() {
    // Jangan panggil loadUserData() secara langsung di constructor jika belum login
  }

  // Ambil data profil & aktivitas dari Firestore berdasarkan User yang sedang Login
  Future<void> loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          nama = data['nama'] ?? 'Budi Santoso';
          jabatan = data['jabatan'] ?? 'Fleet Driver Senior';
          nip = data['nip'] ?? 'EMP-2024-089';
          kontak = data['kontak'] ?? '+62 812-3456-7890';
          fotoProfil = data['fotoProfil'] ?? 'https://i.pravatar.cc/150?img=12';
          fotoBase64 = data['fotoBase64']; // Ambil string base64 dari database
          nomorKendaraan = data['nomorKendaraan'] ?? 'B 1234 ABC';
        }

        // Ambil riwayat aktivitas dari sub-koleksi Firestore
        QuerySnapshot activitySnap = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('activities')
            .get();

        if (activitySnap.docs.isNotEmpty) {
          activities = activitySnap.docs
              .map((e) => ActivityModel.fromJson(e.data() as Map<String, dynamic>))
              .toList();
        } else {
          activities = [
            ActivityModel(
              title: 'Input BBM Berhasil',
              time: 'Tadi, 08:30 WIB',
              detail: '45 Liter',
              iconCode: Icons.local_gas_station.codePoint,
            ),
          ];
        }
        notifyListeners();
      } catch (e) {
        debugPrint("Gagal memuat data: $e");
      }
    }
  }

  // Update profil secara online ke Firestore (termasuk fotoBase64)
  Future<void> updateProfile({
    required String newNama,
    required String newJabatan,
    required String newNip,
    required String newKontak,
    String? newFoto,
    String? newBase64,
  }) async {
    nama = newNama;
    jabatan = newJabatan;
    nip = newNip;
    kontak = newKontak;
    if (newFoto != null) fotoProfil = newFoto;
    if (newBase64 != null) fotoBase64 = newBase64;

    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'nama': nama,
        'jabatan': jabatan,
        'nip': nip,
        'kontak': kontak,
        'fotoProfil': fotoProfil,
        'fotoBase64': fotoBase64, // Simpan string Base64 ke Firestore
      }, SetOptions(merge: true));
    }

    notifyListeners();
  }

  // Fungsi update nomor kendaraan
  Future<void> updateKendaraan(String newKendaraan) async {
    nomorKendaraan = newKendaraan;
    
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'nomorKendaraan': nomorKendaraan,
      }, SetOptions(merge: true));
    }

    notifyListeners();
  }

  // Tambah aktivitas dan simpan ke Firestore
  Future<void> addActivity(ActivityModel activity) async {
    activities.insert(0, activity);
    
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add(activity.toJson());
    }

    notifyListeners();
  }
}

final appData = AppData();