import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(width: 0.2, color: CustomColors.dustyRose),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(3, 3),
            ),
          ],
          color: Color(0xffFFC1CC).withOpacity(0.2),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                    color: Colors.grey.shade300),
                child: Icon(
                  Icons.person_2_rounded,
                  size: 30,
                  color: CustomColors.dustyRose,
                ),
              ),
              SizedBox(
                width: 15,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yash Phapunkar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Plot no: 212',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700),
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
