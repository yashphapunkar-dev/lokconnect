import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UploadingModal extends StatelessWidget {
  const UploadingModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.all(Radius.circular(30)),
             boxShadow: [new BoxShadow(
            color: Colors.grey,
            blurRadius: 40.0,
          ),]
        ),
  
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/uploaddoclot.json',
                height: 150,
                repeat: true,
              ),
              const SizedBox(height: 20),
              const Text(
                "Please wait.\nUpdating files, it may take a while.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
