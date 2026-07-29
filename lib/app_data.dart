import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String title;
  final String time;
  final String detail;
  final int iconCode;
  final String? imageBase64;
  final String nomorKendaraan;

  ActivityModel({
    required this.title,
    required this.time,
    required this.detail,
    required this.iconCode,
    this.imageBase64,
    required this.nomorKendaraan,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'detail': detail,
        'iconCode': iconCode,
        'imageBase64': imageBase64,
        'nomorKendaraan': nomorKendaraan,
      };

  factory ActivityModel.fromJson(Map<String, dynamic> json) => ActivityModel(
        title: json['title'] ?? '',
        time: json['time'] ?? '',
        detail: json['detail'] ?? '',
        iconCode: json['iconCode'] ?? Icons.history.codePoint,
        imageBase64: json['imageBase64'],
        nomorKendaraan: json['nomorKendaraan'] ?? '-',
      );
}

class AppData extends ChangeNotifier {
  String nama = 'Budi Santoso';
  String jabatan = 'Fleet Driver Senior';
  String nip = 'EMP-2024-089';
  String kontak = '+62 812-3456-7890';
  String fotoProfil = 'https://i.pravatar.cc/150?img=12';
  String? fotoBase64; 
  String nomorKendaraan = "B 1234 ABC"; 

  List<ActivityModel> activities = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          fotoBase64 = data['fotoBase64'];
          nomorKendaraan = data['nomorKendaraan'] ?? 'B 1234 ABC';
        }

        // --- CEK APAKAH YANG LOGIN ADALAH ADMIN ---
        if (user.email == 'admin@ecofleet.com') {
          activities = [];
          QuerySnapshot allUsersSnapshot = await _firestore.collection('users').get();
          
          for (var userDoc in allUsersSnapshot.docs) {
            QuerySnapshot activitySnap = await _firestore
                .collection('users')
                .doc(userDoc.id)
                .collection('activities')
                .get();

            for (var actDoc in activitySnap.docs) {
              final data = actDoc.data() as Map<String, dynamic>;
              activities.add(ActivityModel(
                title: data['title'] ?? '',
                time: data['time'] ?? '',
                detail: data['detail'] ?? '',
                iconCode: data['iconCode'] ?? Icons.history.codePoint,
                imageBase64: data.containsKey('imageBase64') ? data['imageBase64'] : null,
                nomorKendaraan: data.containsKey('nomorKendaraan') ? data['nomorKendaraan'] : '-',
              ));
            }
          }
        } else {
          QuerySnapshot activitySnap = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('activities')
              .get();

          if (activitySnap.docs.isNotEmpty) {
            activities = activitySnap.docs.map((e) {
              final data = e.data() as Map<String, dynamic>;
              return ActivityModel(
                title: data['title'] ?? '',
                time: data['time'] ?? '',
                detail: data['detail'] ?? '',
                iconCode: data['iconCode'] ?? Icons.history.codePoint,
                imageBase64: data.containsKey('imageBase64') ? data['imageBase64'] : null,
                nomorKendaraan: data.containsKey('nomorKendaraan') ? data['nomorKendaraan'] : '-',
              );
            }).toList();
          } else {
            activities = [];
          }
        }

        notifyListeners();
      } catch (e) {
        debugPrint("Gagal memuat data: $e");
      }
    }
  }

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
        'fotoBase64': fotoBase64,
      }, SetOptions(merge: true));
    }

    notifyListeners();
  }

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

  void addActivity(ActivityModel activity) {
    activities.insert(0, activity);
    
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add(activity.toJson());
    }

    notifyListeners();
  }

  // --- FUNGSI CRUD: DELETE (Menghapus aktivitas dari list & Firestore) ---
  void removeActivity(ActivityModel activity) {
    activities.remove(activity);
    
    User? user = _auth.currentUser;
    if (user != null) {
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .where('time', isEqualTo: activity.time)
          .where('detail', isEqualTo: activity.detail)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    }

    notifyListeners();
  }
}

final appData = AppData();