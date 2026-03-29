import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PremiumFeatureCard extends StatelessWidget {
  const PremiumFeatureCard({super.key, 
    required this.isPreviewVisible,
    required this.onUnlockPressed,
  });

  final bool isPreviewVisible;
  final VoidCallback onUnlockPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const _PremiumRow(
              icon: CupertinoIcons.mic,
              title: 'その場で録音',
              text: '診察中にそのままレコーディング開始。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.arrow_up_doc,
              title: '音声ファイルアップロード',
              text: 'あとから保存済みファイルを取り込み可能。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.text_bubble,
              title: '日本語 / 韓国語 文字起こし',
              text: '録音内容を読める形で残す。',
            ),
            const Divider(height: 28),
            const _PremiumRow(
              icon: CupertinoIcons.sparkles,
              title: 'AI要約',
              text: '費用、術式、注意点を要約。',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onUnlockPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE2ECFF),
                  foregroundColor: const Color(0xFF24365F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(isPreviewVisible ? '有料機能UIを閉じる' : '有料機能をアンロック'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PremiumRow extends StatelessWidget {
  const _PremiumRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF24365F)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF1D2740),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(color: Color(0xFF61708E), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    );
  }
}