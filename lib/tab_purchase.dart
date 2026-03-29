import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('買い切りプラン', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            '相談中の録音から、文字起こしと要点整理まで一気に残せる拡張機能です。',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF24365F), Color(0xFF2D8C98)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '一度の購入でずっと使える',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Premium Memo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '¥1,000',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF24365F),
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('購入する'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.mic,
            title: '録音',
            description: 'その場で録音開始。既存の音声ファイルアップロードにも対応。',
          ),
          const SizedBox(height: 12),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.globe,
            title: '文字起こし',
            description: '日本語または韓国語の音声をテキスト化して保存。',
          ),
          const SizedBox(height: 12),
          const _PurchaseBenefitTile(
            icon: CupertinoIcons.sparkles,
            title: 'AI要約',
            description: 'AI を使って診察内容の要点を短く整理。',
          ),
        ],
      ),
    );
  }
}

class _PurchaseBenefitTile extends StatelessWidget {
  const _PurchaseBenefitTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F4F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF245A68)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(description),
        ),
      ),
    );
  }
}