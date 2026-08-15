import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/theme/app_palette.dart';
import 'package:lokconnect/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:lokconnect/features/admin_user_service.dart';
import 'package:lokconnect/features/home/bloc/home_bloc.dart';
import 'package:lokconnect/features/splashscreen/splashscreen.dart';
import 'package:lokconnect/features/user_addition/bloc/user_addition_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
    
  );
  // await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);

  // 2. Activate App Check with Debug Providers
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // 3. Create instance of AdminUserService first so it can be passed safely
  final adminUserService = AdminUserService();

  runApp(
    MultiProvider(
      providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
        // Provide the created AdminUserService instance
        ChangeNotifierProvider<AdminUserService>.value(
          value: adminUserService,
        ),
        BlocProvider(
          create: (context) => UserAdditionBloc(
            storage: FirebaseStorage.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
        BlocProvider(
          create: (context) => HomeBloc(
            role: adminUserService.role?.trim() ?? '',
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return MaterialApp(
      theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: themeController.mode,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}