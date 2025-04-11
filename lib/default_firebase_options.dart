import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if(kIsWeb) {
    return FirebaseOptions(
      apiKey: "AIzaSyDK4KXDUNwHZxehgDFHeCX5I6SWjJau4ik",
      authDomain: "lokconnect.firebaseapp.com",
      projectId: "lokconnect",
      storageBucket: "lokconnect.firebasestorage.app",
      messagingSenderId: "707519257282",
      appId: "1:707519257282:android:d2a01886e04946e487b95b",
    );
    } 
      else {
      return FirebaseOptions(
        apiKey: "AIzaSyDK4KXDUNwHZxehgDFHeCX5I6SWjJau4ik",
        appId: "1:707519257282:android:d2a01886e04946e487b95b",
        messagingSenderId: "your-messaging-sender-id",
        projectId: "lokconnect",
        storageBucket: "lokconnect.firebasestorage.app",
      );
    }
  }
}