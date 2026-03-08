import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
      return FirebaseOptions(
        apiKey: "AIzaSyDK4KXDUNwHZxehgDFHeCX5I6SWjJau4ik",
        appId: "1:707519257282:ios:fff508e34ff135aa87b95b",
        messagingSenderId: "your-messaging-sender-id",
        projectId: "lokconnect1",
        storageBucket: "lokconnect.firebasestorage.app",
      );
  }
}