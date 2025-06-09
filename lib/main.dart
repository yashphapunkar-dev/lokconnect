import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lokconnect/features/home/ui/home.dart';
import "package:lokconnect/features/splashscreen/splashscreen.dart";
import 'package:firebase_core/firebase_core.dart';
import 'package:lokconnect/default_firebase_options.dart';
import 'package:lokconnect/features/user_addition/bloc/user_addition_bloc.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // name: 'lokconnect',
    options: DefaultFirebaseOptions.currentPlatform
    );
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => UserAdditionBloc(
          storage: FirebaseStorage.instance,
          firestore: FirebaseFirestore.instance,
        )),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: SplashScreen(),
    );
  }
}
