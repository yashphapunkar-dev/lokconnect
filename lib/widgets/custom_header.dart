import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPress;

  const CustomHeader({
    Key? key,
    required this.title,
    this.showBackButton = false,
    this.onBackPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white,
              ),
              onPressed: onBackPress ?? () => Navigator.pop(context),
            )
          : null,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}