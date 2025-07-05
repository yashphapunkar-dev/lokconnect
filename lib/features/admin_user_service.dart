import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminUserService with ChangeNotifier {

  String? role;
  Map<String, dynamic>? userData;

  bool get isAdmin => role == 'superadmin';
  bool get isLoaded => role != null;

  Future<void> loadAdminData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
    if (doc.exists) {
      userData = doc.data();
      role = userData?['role'];
      notifyListeners(); // <- This triggers UI updates if needed
    }
  }
}

