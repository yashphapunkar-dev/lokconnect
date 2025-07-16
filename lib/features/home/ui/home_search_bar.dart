import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/widgets/custom_input.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const HomeSearchBar({
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        color: CustomColors.primaryColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: CustomInput(
          textController: searchController,
          hintText: 'Enter first name or plot number to search',
          onChanged: onSearchChanged,
        ),
      ),
    );
  }
}

