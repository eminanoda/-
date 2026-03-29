import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BackgroundGlow extends StatelessWidget {
  const BackgroundGlow({super.key, 
    required this.alignment,
    required this.color,
    required this.size,
  });

  final Alignment alignment;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.24),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 80,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
