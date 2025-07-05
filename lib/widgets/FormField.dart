import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart'; // Assuming CustomTextStyle is defined here

// Dummy CustomTextStyle for demonstration if not provided elsewhere
class CustomTextStyle {
  static const TextStyle subHeadingTextStyle = TextStyle(
    color: Colors.grey, // Example color
    fontSize: 14,
  );
}

class CustomFormField extends StatelessWidget {
  final String title;
  final Function(String) onChanged;
  // New: Optional validator function
  final String? Function(String?)? validator;
  // New: Optional TextEditingController for scenarios where it's needed
  final TextEditingController? controller;


  const CustomFormField({ // Changed to const constructor
    super.key,
    required this.title,
    required this.onChanged,
    this.validator, // Make it optional
    this.controller, // Make it optional
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 15), // Added const
      padding: const EdgeInsets.symmetric(horizontal: 20), // Added const
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)), // Added const
        color: Colors.white,
      ),
      child: TextFormField(
        controller: controller, // Assign controller if provided
        decoration: InputDecoration(
          labelText: title, // Directly use title as label
          labelStyle: CustomTextStyle.subHeadingTextStyle,
          border: InputBorder.none,
          // Removed the hardcoded validator logic for label here
        ),
        onChanged: onChanged,
        // Pass the external validator directly
        validator: validator,
      ),
    );
  }
}