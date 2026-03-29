import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PremiumAiSummaryCard extends StatelessWidget {
  const PremiumAiSummaryCard({super.key, this.summary});

  final String? summary;

  @override
  Widget build(BuildContext context) {
    final displayText = summary ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF24365F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: Color(0xFF9FE7E0), size: 18),
              SizedBox(width: 8),
              Text(
                'AI要約',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayText,
            style: const TextStyle(color: Color(0xFFE9F1FF), height: 1.5),
          ),
        ],
      ),
    );
  }
}
