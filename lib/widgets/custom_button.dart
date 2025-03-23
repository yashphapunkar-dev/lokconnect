import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPress;
  final String buttonText;
  const CustomButton(
      {super.key, required this.onPress, required this.buttonText});

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widthHandler(width)),
      child: InkWell(
        onTap: (){
          onPress();
        },
        child: Container(
          decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.all(Radius.circular(15))),
          margin: EdgeInsets.only(top: 10, bottom: 50, right: 20, left: 20),
          child: Center(
              child: Text(
            buttonText,
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          )),
        ),
      ),
    );
  }
}
