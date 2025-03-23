import 'package:flutter/material.dart';
import 'package:lokconnect/constants/custom_colors.dart';
import 'package:lokconnect/widgets/custom_header.dart';

class PageLayout extends StatelessWidget {
  final Widget child;
  final String pageTitle;
  final Color color;
  const PageLayout({super.key, required this.child, required this.pageTitle, this.color = CustomColors.primaryColor});

  @override
  Widget build(BuildContext context) {
  var height = MediaQuery.sizeOf(context).height;
    
    return Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: height * .15,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(50))),
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: CustomHeader(
                          title: pageTitle,
                          showBackButton: true,
                        )),
                  ),
                  Container(
                    color: color,
                    child: Container(
                      height: height * .8,
                      decoration: BoxDecoration(
                          color: CustomColors.primaryColor,
                          borderRadius:
                              BorderRadius.only(topLeft: Radius.circular(50))),
                      child: child,
                    ),
                  ),
                ],
              ),
            
            ],
        );
  }
}