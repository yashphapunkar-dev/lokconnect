import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController textController;
  final Function(String?)? onSubmit;
  CustomInput({super.key, this.hintText = ' ', required this.textController, this.title = '', this.onSubmit, });

double widthHandler(double width) {
  if (width <= 768) {
    return 0;
  } else if (width >= 768 && width < 1280) { 
    return 200;
  } else if (width >= 1280) { 
    return 500;
  } 
  return 0;
}

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title != '' ? Padding(
          padding: EdgeInsets.only(left: 5, bottom: 8),
          child: Text(title, 
          style: TextStyle(
            color: Colors.grey.shade800,
            fontSize: 16,
            fontWeight: FontWeight.w600
            ),),
        ) : SizedBox.shrink(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: widthHandler(width)),
          child: TextField(
            onSubmitted: (value) { 
              onSubmit!(value);
            },
            controller: textController,
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
                    borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.shade600),
                contentPadding:
                    EdgeInsets.only(top: 15, bottom: 15, left: 15, right: 15)),
          ),
        ),
      ],
    );
  }
}
