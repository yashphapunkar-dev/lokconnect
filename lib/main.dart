import "package:flutter/material.dart";
import "package:lokconnect/features/splashscreen/splashscreen.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:lokconnect/default_firebase_options.dart';


void main() async  {
   WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
   );
  runApp(MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
    );
  }
}