import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';

class CustomFormField extends StatelessWidget {
  final String title;
  final Function(String) onChanged;
  const CustomFormField(
      {super.key, required this.title, required this.onChanged});

  validator(String? val) {
    return val!.isEmpty ? "Required" : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: EdgeInsets.only(top: 15),
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: Colors.white,
        ),
        child: TextFormField(
            decoration: InputDecoration(
                labelText: "${title}",
                labelStyle: CustomTextStyle.subHeadingTextStyle,
                border: InputBorder.none),
            onChanged: onChanged,
            validator: (val) => validator(val)));
  }
}
