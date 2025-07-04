import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController textController;
  final Function(String?)? onSubmit;
  final Function(String)? onChanged;
  final bool isSecure;
  final Widget? suffixIcon; // New: Optional suffix icon

  const CustomInput({ // Changed to const constructor where possible for performance
    super.key,
    this.hintText = ' ',
    required this.textController,
    this.title = '',
    this.onSubmit,
    this.onChanged,
    this.isSecure = false,
    this.suffixIcon, // Initialize the new property
  });

  double widthHandler(double width) {
    if (width <= 768) {
      return 0;
    } else if (width >= 768 && width < 1280) {
      return 200;
    } else if (width >= 1280) {
      return 500;
    }
    return 0; // Default return for safety, though conditions cover all ranges
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widthHandler(width)),
          child: TextField(
            controller: textController,
            onChanged: onChanged,
            onSubmitted: onSubmit,
            obscureText: isSecure,
            decoration: InputDecoration(
              hintMaxLines: 1,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide(
                  color: Colors.grey.shade100,
                  width: 0.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 15,
              ),
              suffixIcon: suffixIcon, // New: Assign the optional suffixIcon here
            ),
          ),
        ),
      ],
    );
  }
}