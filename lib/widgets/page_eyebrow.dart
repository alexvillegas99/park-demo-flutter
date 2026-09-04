import 'package:flutter/material.dart';

import '../design/brand_theme.dart';

class PageEyebrow extends StatelessWidget {
  final IconData icon;
  final String label;

  const PageEyebrow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.goldDk, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.goldDk,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
          ),
        ),
      ],
    );
  }
}
