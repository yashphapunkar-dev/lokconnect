import 'dart:ui';
import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(
      message,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
    backgroundColor: Colors.black.withOpacity(0.8),
    elevation: 0,
    behavior: SnackBarBehavior.floating, // Makes it float
    margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    duration: Duration(seconds: 2),
  );

  // Show a blurred background effect
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.2),
    barrierDismissible: false,
    builder: (context) {
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Dismiss the blur effect
      });

      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ScaffoldMessenger(
          child: Builder(
            builder: (context) {
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              return Container(); // Empty widget to maintain context
            },
          ),
        ),
      );
    },
  );
}
