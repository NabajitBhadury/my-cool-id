import 'package:flutter/material.dart';

class CustomBorder extends StatelessWidget {
  const CustomBorder({
    super.key,
    required this.size,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Color.fromARGB(255, 218, 79, 15), width: 4),
                  left: BorderSide(
                      color: Color.fromARGB(255, 218, 79, 15), width: 4),
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Color.fromARGB(255, 224, 174, 7), width: 4),
                  right: BorderSide(
                      color: Color.fromARGB(255, 224, 174, 7), width: 4),
                ),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Color.fromARGB(255, 10, 166, 187), width: 4),
                  left: BorderSide(
                      color: Color.fromARGB(255, 10, 166, 187), width: 4),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: Color.fromARGB(255, 50, 180, 55), width: 4),
                  right: BorderSide(
                      color: Color.fromARGB(255, 50, 180, 55), width: 4),
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
