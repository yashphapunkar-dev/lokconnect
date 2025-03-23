import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                  return Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.white,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      height: 65,
                      decoration: BoxDecoration(
                                   color: Colors.white,
                        borderRadius: BorderRadius.circular(15)
                      ),
                    ),
                  );
                }  );
  }
}