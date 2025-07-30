import 'package:flutter/material.dart';

class InfoTile extends StatelessWidget {
  final String value;
  final String filedName;
  TextEditingController? textController = TextEditingController();

   InfoTile({super.key, required this.value, required this.filedName, required this.textController});

  @override
  Widget build(BuildContext context) {
    textController!.text = value;

     widthHandler(double width) {
  if (width >= 1000) return 450; // Desktop
  if (width >= 700) return 250;  // Tablet
  return double.maxFinite;                    // Mobile
}


    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            filedName,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          Container(
            child: SizedBox(
              width: widthHandler(MediaQuery.sizeOf(context).width).toDouble(),
              child: TextField(
                controller: textController,
                
                decoration:  InputDecoration(
                  fillColor: Colors.white,
                    filled: true,
                  // border: OutlineInputBorder(),
                  isDense: true,
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0),
                  borderSide: BorderSide.none,
                ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
