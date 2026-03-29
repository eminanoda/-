import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PremiumAiSummaryCard extends StatelessWidget {
  const PremiumAiSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF24365F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          SizedBox(height: 12),
          Text(
            '・腫れのピークは術後2日目\n・抜糸は7日後\n・費用は麻酔代込み\n・大事な予定は1週間後以降が無難',
            style: TextStyle(color: Color(0xFFE9F1FF), height: 1.5),
          ),
        ],
      ),
    );
  }
}
